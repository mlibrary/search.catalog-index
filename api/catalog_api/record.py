from __future__ import annotations
from catalog_api.solr_client import SolrClient
import pymarc
import io
import re
import string
from dataclasses import dataclass
from collections.abc import Callable


def record_for(id: str) -> Record:
    data = SolrClient().get_record(id)
    return Record(data)


class SolrDoc:
    def __init__(self, data: dict):
        self.data = data

    @property
    def id(self):
        return self.data["id"]

    @property
    def title(self):
        return self._get_paired_field("title_display")

    @property
    def published(self) -> list:
        return self._get_paired_field("publisher_display")

    @property
    def edition(self) -> list:
        return self._get_paired_field("edition")

    @property
    def lcsh_subjects(self):
        return self._get_text_field("lc_subject_display")

    @property
    def language(self):
        return self._get_text_field("language")

    @property
    def isbn(self):
        return self._get_text_field("isbn")

    @property
    def issn(self):
        return self._get_text_field("issn")

    @property
    def gov_doc_no(self):
        return self._get_text_field("sudoc")

    @property
    def report_number(self):
        return self._get_text_field("rptnum")

    @property
    def call_number(self):
        return self._get_text_field("callnumber_browse")

    @property
    def oclc(self):
        return self._get_text_field("oclc")

    @property
    def availability(self) -> list:
        return self._get_list("availability")

    @property
    def format(self):
        return self._get_list("format")

    @property
    def main_author(self):
        main = self.data.get("main_author_display") or []
        search = self.data.get("main_author") or []

        match len(main):
            case 0:
                return []
            case 1:
                return [
                    {
                        "original": {
                            "text": main[0],
                            "search": [{"field": "author", "value": search[0]}],
                            "browse": search[0],
                        }
                    }
                ]
            case _:
                return [
                    {
                        "transliterated": {
                            "text": main[0],
                            "search": [{"field": "author", "value": search[0]}],
                            "browse": search[0],
                        },
                        "original": {
                            "text": main[1],
                            "search": [{"field": "author", "value": search[1]}],
                            "browse": search[1],
                        },
                    }
                ]

    @property
    def academic_discipline(self):
        return [
            {"list": discipline.split(" | ")}
            for discipline in self._get_list("hlb3Delimited")
        ]

    def _get_list(self, key):
        return self.data.get(key) or []

    def _get_text_field(self, key):
        return [{"text": value} for value in (self.data.get(key) or [])]

    def _get_paired_field(self, key):
        values = self.data.get(key) or []
        match len(values):
            case 0:
                return []
            case 1:
                return [{"original": {"text": values[0]}}]
            case _:
                return [
                    {
                        "transliterated": {"text": values[0]},
                        "original": {"text": values[1]},
                    }
                ]


class MARC:
    def __init__(self, record: pymarc.record.Record):
        self.record = record

    @property
    def preferred_title(self) -> list:
        no_l = string.ascii_lowercase.replace("l", "")
        no_i = string.ascii_lowercase.replace("i", "")
        rulesets = [
            FieldRuleset(
                tags=["130", "240", "243"],
                search=[{"subfields": no_l, "field": "title"}],
            ),
            FieldRuleset(
                tags=["730"],
                text_sfs=no_i,
                search=[{"subfields": no_i, "field": "title"}],
                filter=lambda field: (field.indicator2 == "2"),
            ),
        ]
        return self._generate_paired_fields(rulesets)

    @property
    def related_title(self) -> list:
        no_i = string.ascii_lowercase.replace("i", "")
        display_sfs = "abcdefgjklmnopqrst"

        def is_a_title(field: pymarc.Field) -> bool:
            return field.get_subfields("t") and field.indicator2 != "2"

        rulesets = [
            FieldRuleset(
                tags=["730"],
                text_sfs=no_i,
                search=[{"subfields": no_i, "field": "title"}],
                filter=lambda field: (not field.indicator2),
            ),
            FieldRuleset(
                tags=["700", "710"],
                text_sfs=display_sfs,
                search=[{"subfields": "fjklmnoprst", "field": "title"}],
                filter=is_a_title,
            ),
            FieldRuleset(
                tags=["711"],
                text_sfs=display_sfs,
                search=[{"subfields": "fklmnoprst", "field": "title"}],
                filter=is_a_title,
            ),
        ]
        return self._generate_paired_fields(rulesets)

    @property
    def other_titles(self) -> list:
        """
        Could add "tag" and "linkage" to the output to enable matching up parallel fields
        I wouldn't want to fetch any paired fields from solr then though
        """

        def is_a_title(field: pymarc.Field) -> bool:
            return field.get_subfields("t") and field.indicator2 == "2"

        rulesets = (
            FieldRuleset(
                tags=["246", "247", "740"],
                search=[{"subfields": string.ascii_lowercase, "field": "title"}],
            ),
            FieldRuleset(
                tags=["700", "710"],
                text_sfs="abcdefgjklmnopqrst",
                search=[{"subfields": "fkjlmnoprst", "field": "title"}],
                filter=is_a_title,
            ),
            FieldRuleset(
                tags=["711"],
                text_sfs="abcdefgjklmnopqrst",
                search=[{"subfields": "fklmnoprst", "field": "title"}],
                filter=is_a_title,
            ),
        )

        return self._generate_paired_fields(rulesets)

    @property
    def new_title(self):
        ruleset = FieldRuleset(
            tags=["785"],
            text_sfs="ast",
            search=[
                {"subfields": "a", "field": "author"},
                {"subfields": "st", "field": "title"},
            ],
        )
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def new_title_issn(self):
        ruleset = FieldRuleset(
            tags=["785"],
            text_sfs="x",
        )
        return self._generate_unpaired_fields(tuple([ruleset]))

    @property
    def previous_title(self):
        ruleset = FieldRuleset(
            tags=["780"],
            text_sfs="ast",
            search=[
                {"subfields": "a", "field": "author"},
                {"subfields": "st", "field": "title"},
            ],
        )
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def previous_title_issn(self):
        ruleset = FieldRuleset(
            tags=["780"],
            text_sfs="x",
        )
        return self._generate_unpaired_fields(tuple([ruleset]))

    @property
    def contributors(self):
        search_sfs = "abcdgjkqu"
        ruleset = FieldRuleset(
            tags=["700", "710", "711"],
            search=[{"subfields": search_sfs, "field": "author"}],
            text_sfs="abcdefgjklnpqu4",
            browse_sfs=search_sfs,
            filter=lambda field: (
                not field.get_subfields("t") and field.indicator2 != "2"
            ),
        )

        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def created(self):
        rulesets = (
            FieldRuleset(tags=["264"], filter=lambda field: (field.indicator2 == "0")),
        )

        return self._generate_paired_fields(rulesets)

    @property
    def distributed(self):
        rulesets = (
            FieldRuleset(tags=["264"], filter=lambda field: (field.indicator2 == "2")),
        )

        return self._generate_paired_fields(rulesets)

    @property
    def manufactured(self):
        rulesets = (
            FieldRuleset(tags=["260"], text_sfs="efg"),
            FieldRuleset(tags=["264"], filter=lambda field: (field.indicator2 == "3")),
        )

        return self._generate_paired_fields(rulesets)

    @property
    def series(self):
        ruleset = FieldRuleset(tags=["400", "410", "411", "440", "490"])
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def series_statement(self):
        ruleset = FieldRuleset(tags=["440", "800", "810", "811", "830"])
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def biography_history(self):
        ruleset = FieldRuleset(tags=["545"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def summary(self):
        ruleset = FieldRuleset(
            tags=["520"],
            text_sfs="abc3",
            filter=lambda field: (field.indicator1 != "4"),
        )
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def in_collection(self):
        ruleset = FieldRuleset(tags=["773"])
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def access(self):
        ruleset = FieldRuleset(tags=["506"], text_sfs="abc")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def finding_aids(self):
        ruleset = FieldRuleset(tags=["555"], text_sfs="abcd3u")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def terms_of_use(self):
        ruleset = FieldRuleset(tags=["540"])
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def language_note(self):
        ruleset = FieldRuleset(tags=["546"])
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def performers(self):
        ruleset = FieldRuleset(tags=["511"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def date_place_of_event(self):
        ruleset = FieldRuleset(tags=["518"], text_sfs="adop23")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def preferred_citation(self):
        ruleset = FieldRuleset(tags=["524"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def location_of_originals(self):
        ruleset = FieldRuleset(tags=["535"], text_sfs=f"{string.ascii_lowercase}3")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def funding_information(self):
        ruleset = FieldRuleset(tags=["536"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def source_of_acquisition(self):
        ruleset = FieldRuleset(tags=["541"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def related_items(self):
        ruleset = FieldRuleset(tags=["580"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def numbering(self):
        ruleset = FieldRuleset(tags=["362"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def current_publication_frequency(self):
        ruleset = FieldRuleset(tags=["310"], text_sfs="ab")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def former_publication_frequency(self):
        ruleset = FieldRuleset(tags=["321"], text_sfs="ab")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def numbering_notes(self):
        ruleset = FieldRuleset(tags=["515"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def source_of_description_note(self):
        ruleset = FieldRuleset(tags=["588"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def copy_specific_note(self):
        ruleset = FieldRuleset(tags=["590"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def references(self):
        ruleset = FieldRuleset(tags=["510"])
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def copyright_status_information(self):
        ruleset = FieldRuleset(tags=["542"])
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def note(self):
        ruleset = FieldRuleset(
            tags=[
                "500",
                "501",
                "502",
                "525",
                "526",
                "530",
                "547",
                "550",
                "552",
                "561",
                "565",
                "584",
                "585",
            ],
            text_sfs="a",
        )
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def arrangement(self):
        ruleset = FieldRuleset(tags=["351"], text_sfs="ab3")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def copyright(self):
        ruleset = FieldRuleset(
            tags=["264"], filter=lambda field: (field.indicator2 == "4")
        )

        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def physical_description(self):
        ruleset = FieldRuleset(tags=["300"])
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def map_scale(self):
        ruleset = FieldRuleset(tags=["255"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def reproduction_note(self):
        ruleset = FieldRuleset(tags=["533"], text_sfs=f"{string.ascii_lowercase}35")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def original_version_note(self):
        ruleset = FieldRuleset(tags=["534"], text_sfs=f"{string.ascii_lowercase}35")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def playing_time(self):
        ruleset = FieldRuleset(tags=["306"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def media_format(self):
        ruleset = FieldRuleset(tags=["538"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def audience(self):
        ruleset = FieldRuleset(tags=["521"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def content_advice(self):
        ruleset = FieldRuleset(
            tags=["520"],
            text_sfs="abc3",
            filter=lambda field: (field.indicator1 == "4"),
        )
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def awards(self):
        ruleset = FieldRuleset(tags=["586"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def production_credits(self):
        ruleset = FieldRuleset(tags=["508"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def bibliography(self):
        ruleset = FieldRuleset(tags=["504"], text_sfs="a")
        return self._generate_paired_fields(tuple([ruleset]))

    @property
    def publisher_number(self):
        ruleset = FieldRuleset(tags=["028"], text_sfs="ab")
        return self._generate_paired_fields(tuple([ruleset]))

    # @property
    # def chronology(self):
    #     ruleset = FieldRuleset(tags=["945"], text_sfs="a")
    #     return self._generate_paired_fields(tuple([ruleset]))

    # @property
    # def place(self):
    #     ruleset = FieldRuleset(tags=["946"], text_sfs="a")
    #     return self._generate_paired_fields(tuple([ruleset]))

    # @property
    # def printer(self):
    #     ruleset = FieldRuleset(tags=["947"], text_sfs="a")
    #     return self._generate_paired_fields(tuple([ruleset]))

    # @property
    # def association(self):
    #     ruleset = FieldRuleset(tags=["948"], text_sfs="a")
    #     return self._generate_paired_fields(tuple([ruleset]))

    def _generate_unpaired_fields(self, rulesets: tuple) -> list:
        result = []
        for ruleset in rulesets:
            for field in self.record.get_fields(*ruleset.tags):
                if ruleset.has_any_subfields(field):
                    result.append(ruleset.value_for(field))

        return set(result)

    def _generate_paired_fields(self, rulesets: tuple) -> list:
        result = []
        for ruleset in rulesets:
            for fields in self._get_paired_fields_for(ruleset):
                if ruleset.filter(fields["original"]):
                    r = {}
                    for key in fields.keys():
                        r[key] = ruleset.value_for(fields[key])
                    result.append(PairedField(**r))
        return result

    def _get_original_for_tags(self, tags: tuple) -> list:
        def linkage_has_tag(field):
            return Linkage(field).tag in tags

        return list(filter(linkage_has_tag, self.record.get_fields("880")))

    def _get_paired_fields_for(self, ruleset: FieldRuleset) -> list:
        mapping = {}
        for field in self._get_original_for_tags(ruleset.tags):
            mapping[Linkage(field).__str__()] = field

        results = []
        for field in self.record.get_fields(*ruleset.tags):
            if ruleset.has_any_subfields(field):
                original = mapping.pop(
                    f"{field.tag}-{Linkage(field).occurence_number}", None
                )
                if original:
                    results.append({"transliterated": field, "original": original})
                else:
                    results.append({"original": field})

        return results + [
            {"original": f} for f in mapping.values() if ruleset.has_any_subfields(f)
        ]


class Linkage:
    def __init__(self, field: pymarc.Field):
        if field.get("6"):
            self.parts = re.split("[-/]", field["6"])
        else:
            self.parts = [None, None]

    @property
    def tag(self):
        return self.parts[0]

    @property
    def occurence_number(self):
        return self.parts[1]

    def __str__(self):
        return f"{self.tag}-{self.occurence_number}"


@dataclass(frozen=True)
class SearchField:
    field: str
    value: str


@dataclass(frozen=True)
class FieldElement:
    text: str
    tag: str
    search: list[SearchField] | None = None
    browse: str | None = None


@dataclass(frozen=True)
class PairedField:
    original: FieldElement
    transliterated: FieldElement | None = None


@dataclass(frozen=True)
class FieldRuleset:
    tags: list
    text_sfs: str = string.ascii_lowercase
    search: list | None = None
    browse_sfs: str | None = None
    filter: Callable[..., bool] = lambda field: True

    def has_any_subfields(self, field: pymarc.Field) -> bool:
        return bool(self._get_subfields(field, self.text_sfs))

    def value_for(self, field: pymarc.Field):
        result = {
            "text": self._get_subfields(field, self.text_sfs).strip(),
            "tag": field.tag,
        }

        if self.search:
            result["search"] = []
            for s in self.search:
                value = self._get_subfields(field, s["subfields"])
                if value:
                    result["search"].append(
                        SearchField(
                            field=s["field"],
                            value=self._get_subfields(field, s["subfields"]),
                        )
                    )

        if self.browse_sfs:
            result["browse"] = self._get_subfields(field, self.browse_sfs)

        return FieldElement(**result)

    def _get_subfields(self, field: pymarc.Field, subfields: str):
        return " ".join(field.get_subfields(*tuple(subfields)))


class Record(SolrDoc, MARC):
    def __init__(self, data: dict):
        self.data = data
        self.record = pymarc.parse_xml_to_array(io.StringIO(data["fullrecord"]))[0]
        SolrDoc.__init__(self, data)
        MARC.__init__(self, self.record)
