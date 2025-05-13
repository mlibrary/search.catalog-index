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
    def physical_description(self):
        ruleset = FieldRuleset(tags=["300"])
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

    def _generate_paired_fields(self, rulesets: tuple) -> list:
        result = []
        for ruleset in rulesets:
            for fields in self._get_paired_fields_for(ruleset):
                if ruleset.filter(fields["original"]):
                    r = {}
                    for key in fields.keys():
                        r[key] = ruleset.value_for(fields[key])
                    result.append(r)
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
            "text": self._get_subfields(field, self.text_sfs),
            "tag": field.tag,
        }

        if self.search:
            result["search"] = [
                {
                    "field": s["field"],
                    "value": self._get_subfields(field, s["subfields"]),
                }
                for s in self.search
            ]

        if self.browse_sfs:
            result["browse"] = self._get_subfields(field, self.browse_sfs)

        return result

    def _get_subfields(self, field: pymarc.Field, subfields: str):
        return " ".join(field.get_subfields(*tuple(subfields)))


class Record(SolrDoc, MARC):
    def __init__(self, data: dict):
        self.data = data
        self.record = pymarc.parse_xml_to_array(io.StringIO(data["fullrecord"]))[0]
        SolrDoc.__init__(self, data)
        MARC.__init__(self, self.record)
