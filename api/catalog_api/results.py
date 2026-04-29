import requests
import re
from dataclasses import dataclass
from catalog_api.record import Record
from catalog_api.services import S


def get_results(query_params: dict):
    parser_params = {
        "query": query_params["query"],
        "start": query_params["offset"],
        "rows": query_params["limit"],
        "fq[]": FilterQuery(query_params).query(),
        "sort": Results.sort_map[query_params["sort"]],
    }
    response = requests.Session().get(
        f"{S.parser_url}/catalog/search", params=parser_params
    )
    return Results(data=response.json(), query_params=query_params)


class Results:
    sort_map = {
        "relevance": "score desc",
        "date_asc": "publishDateTrie asc",
        "date_desc": "publishDateTrie desc",
        "author_asc": "authorSort asc",
        "author_desc": "authorSort desc",
        "date_added": "cat_date desc",
        "title_asc": "titleSort asc",
        "title_desc": "titleSort desc",
    }

    inverse_sort_map = {v: k for k, v in sort_map.items()}

    def __init__(self, data: dict, query_params: dict):
        self.data = data
        self.query_params = query_params

    @property
    def records(self):
        return [Record(data) for data in self.data["response"]["docs"]]

    @property
    def filters(self):
        facet_fields = self.data["facet_counts"]["facet_fields"]

        result = []
        for f in facet_fields.keys():
            if f in facet_to_filter:
                if f == "availability":
                    r = AvailabilityFilter(
                        field=f,
                        values=facet_fields[f],
                        ht_search_only=self.query_params["ht_search_only"],
                    )
                else:
                    r = Filter(field=f, values=facet_fields[f])
                result.append(r)
        # result = [
        # Filter(field=x, values=facet_fields[x])
        # for x in facet_fields.keys()
        # if x in filter_to_facet
        # ]

        return result

    @property
    def total(self):
        return self.data["response"]["numFound"]

    @property
    def limit(self):
        return self.data["responseHeader"]["params"]["rows"]

    @property
    def offset(self):
        return self.data["response"]["start"]

    @property
    def sort(self):
        return self.inverse_sort_map[self.data["responseHeader"]["params"]["sort"]]


def solr_escape(string):
    result = re.sub(r'([+\-&|!(){}\[\]\^"~*?:\\\/])', r"\\\1", string)
    return re.sub(r"\s+", "\\\\ ", result)


filter_to_facet = {
    "availability": "availability",
    "format": "format",
    "subject": "topicStr",
    "date_of_publication": "publishDateRange",
    "language": "language",
    "collection": "collection",
    "academic_discipline": "hlb3Str",
    "author": "authorStr",
    "place_of_publication": "place_of_publication",
    "region": "geographicStr",
    "location": "building",
    "library": "institution",
}

facet_to_filter = {}

for filter_field in filter_to_facet.keys():
    facet_to_filter[filter_to_facet[filter_field]] = filter_field


def facet_field_for(f):
    if f in filter_to_facet:
        return filter_to_facet[f]


def filter_field_for(f):
    if f in facet_to_filter:
        return facet_to_filter[f]


class FilterQuery:
    def __init__(self, data: dict):
        self.data = data
        self.facets = {}
        for f in data["filters"]:
            field, value = f.split(":", 1)
            facet = filter_to_facet[field] if field in filter_to_facet else None
            # if facet isn't in the facet list skip it
            if not facet:
                continue

            if facet not in self.facets:
                self.facets[facet] = []
            self.facets[facet].append(value)

        self.filter_param = [f.split(":", 1) for f in data["filters"]]

    def query(self):
        result = []
        for field in self.facets.keys():
            match field:
                case "availability":
                    next
                case "institution":
                    next
                case _:
                    result.append(self.basic_facet(field, self.facets[field]))

        if self.institution():
            result.append(self.institution())
        result.append(self.availability())
        return result

    def institution(self):
        institution_map = {
            "aa": "UM Ann Arbor Libraries",
            "flint": "Flint Thompson Library",
            "clements": "William L. Clements Library",
            "bentley": "Bentley Historical Library",
            "all": "all",
        }
        if "institution" in self.facets:
            filtered = filter(
                lambda v: v in institution_map.keys(), self.facets["institution"]
            )
            mapped = list(map(lambda v: institution_map[v], filtered))
            if "all" in mapped or not mapped:
                return None
            return self.basic_facet("institution", mapped)

    def availability(self):
        full_text = {
            "Available Online": "hathi_trust_full_text_or_electronic_holding",
            "Hathi Trust": "hathi_trust_full_text",
            "Physical": "physical",
        }
        search_only = {
            "Available Online": "hathi_trust_or_electronic_holding",
            "Hathi Trust": "hathi_trust",
            "Physical": "physical",
        }

        options = search_only if self.data["ht_search_only"] else full_text
        result = f"availability:physical OR availability:{options['Available Online']}"
        if "availability" in self.facets:
            filtered = filter(
                lambda v: v in options.keys(), self.facets["availability"]
            )
            mapped = list(map(lambda v: options[v], filtered))

            if len(mapped) > 0:
                result = " AND ".join(mapped)
                result = f"availability:({result})"

        return f"({result})"

    def basic_facet(self, field, values):
        escaped = map(lambda v: solr_escape(v), values)
        value = " AND ".join(escaped)
        return f"{field}:({value})"


# problems with filter data.
# 1. the fields aren't the correct names
# 2. location filter has the wrong name (time for the other api???)
# 3. some of them (just search only?) are empty
# 4. availability has some special rules
class Filter:
    def __init__(self, field: str, values: list):
        self.field = filter_field_for(field)
        self.values = self.get_values(values)

    def get_values(self, values):
        result = []
        for x in range(0, len(values), 2):
            result.append(FilterValue(text=values[x], count=values[x + 1]))
        return result


class AvailabilityFilter(Filter):
    def __init__(self, field: str, values: list, ht_search_only: bool):
        self.ht_search_only = ht_search_only
        self.field = filter_field_for(field)
        basic_values = self.get_values(values)
        self.values = self.get_availability_values(basic_values, ht_search_only)

    def get_availability_values(self, basic_values, ht_search_only):
        full_text = {
            "hathi_trust_full_text_or_electronic_holding": "Available Online",
            "hathi_trust_full_text": "Hathi Trust",
            "physical": "Physical",
        }
        search_only = {
            "hathi_trust_or_electronic_holding": "Available Online",
            "hathi_trust": "Hathi Trust",
            "physical": "Physical",
        }

        options = search_only if self.ht_search_only else full_text
        result = []
        for bv in basic_values:
            if bv.text in options:
                fv = FilterValue(text=options[bv.text], count=bv.count)
                result.append(fv)

        return result


@dataclass(frozen=True)
class FilterValue:
    text: str
    count: int
