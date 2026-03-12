import json
from pathlib import Path
from dataclasses import dataclass
from catalog_api.record import Record


class Results:
    fixture_path = Path(__file__).parents[0] / "../tests/fixtures/results/"
    with open(fixture_path / "page1.json") as f:
        page1 = json.load(f)

    with open(fixture_path / "page2.json") as f:
        page2 = json.load(f)

    with open(fixture_path / "page3.json") as f:
        page3 = json.load(f)

    def __init__(self, data: dict):
        offset = data["offset"]
        if offset < 10:
            self.data = self.page1
        elif offset < 20:
            self.data = self.page2
        else:
            self.data = self.page3

    @property
    def records(self):
        return [Record(data) for data in self.data["response"]["docs"]]

    @property
    def filters(self):
        facet_fields = self.data["facet_counts"]["facet_fields"]
        return [
            Filter(field=x, values=facet_fields[x])
            for x in facet_fields.keys()
            if x in Filter.filter_field_map
        ]

    @property
    def total(self):
        return self.data["response"]["numFound"]

    @property
    def limit(self):
        return self.data["responseHeader"]["params"]["rows"]

    @property
    def offset(self):
        return self.data["response"]["start"]


# problems with filter data.
# 1. the fields aren't the correct names
# 2. location filter has the wrong name (time for the other api???)
# 3. some of them (just search only?) are empty
# 4. availability has some special rules
class Filter:
    filter_field_map = {
        "availability": "availability",
        "format": "format",
        "topicStr": "subject",
        "publishDateRange": "date_of_publication",
        "language": "language",
        "collection": "collection",
        "hlb3Str": "academic_discipline",
        "authorStr": "author",
        "place_of_publication": "place_of_publication",
        "geographicSt": "region",
        "building": "location",
    }  # institution and search_only are skipped for this

    def __init__(self, field: str, values: list):
        self.field = self.filter_field_map[field]
        self.values = self.get_values(values)

    def get_values(self, values):
        result = []
        for x in range(0, len(values), 2):
            result.append(FilterValue(text=values[x], count=values[x + 1]))
        return result


@dataclass(frozen=True)
class FilterValue:
    text: str
    count: int
