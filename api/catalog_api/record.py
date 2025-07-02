from __future__ import annotations
from catalog_api.solr_client import SolrClient
from catalog_api.marc import Processor, FieldRuleset
import pymarc
import io
import re
import string
import json
from dataclasses import dataclass
from collections.abc import Callable
from catalog_api.holdings import Holdings


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
    def lc_subjects(self):
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
    def gov_doc_number(self):
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
    def remediated_lc_subjects(self):
        return self._get_text_field("remediated_lc_subject_display")

    @property
    def other_subjects(self):
        return self._get_text_field("non_lc_subject_display")

    @property
    def bookplate(self):
        return self._get_text_field("bookplate")

    @property
    def indexing_date(self):
        return self.data.get("date_of_index")

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
        self.processor = Processor(record)

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
        return self.processor.generate_paired_fields(rulesets)

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
        return self.processor.generate_paired_fields(rulesets)

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

        return self.processor.generate_paired_fields(rulesets)

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
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def new_title_issn(self):
        ruleset = FieldRuleset(
            tags=["785"],
            text_sfs="x",
        )
        return self.processor.generate_unpaired_fields(tuple([ruleset]))

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
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def previous_title_issn(self):
        ruleset = FieldRuleset(
            tags=["780"],
            text_sfs="x",
        )
        return self.processor.generate_unpaired_fields(tuple([ruleset]))

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

        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def created(self):
        rulesets = (
            FieldRuleset(tags=["264"], filter=lambda field: (field.indicator2 == "0")),
        )

        return self.processor.generate_paired_fields(rulesets)

    @property
    def distributed(self):
        rulesets = (
            FieldRuleset(tags=["264"], filter=lambda field: (field.indicator2 == "2")),
        )

        return self.processor.generate_paired_fields(rulesets)

    @property
    def manufactured(self):
        rulesets = (
            FieldRuleset(tags=["260"], text_sfs="efg"),
            FieldRuleset(tags=["264"], filter=lambda field: (field.indicator2 == "3")),
        )

        return self.processor.generate_paired_fields(rulesets)

    @property
    def series(self):
        ruleset = FieldRuleset(tags=["400", "410", "411", "440", "490"])
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def series_statement(self):
        ruleset = FieldRuleset(tags=["440", "800", "810", "811", "830"])
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def biography_history(self):
        ruleset = FieldRuleset(tags=["545"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def summary(self):
        ruleset = FieldRuleset(
            tags=["520"],
            text_sfs="abc3",
            filter=lambda field: (field.indicator1 != "4"),
        )
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def in_collection(self):
        ruleset = FieldRuleset(tags=["773"])
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def access(self):
        ruleset = FieldRuleset(tags=["506"], text_sfs="abc")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def finding_aids(self):
        ruleset = FieldRuleset(tags=["555"], text_sfs="abcd3u")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def terms_of_use(self):
        ruleset = FieldRuleset(tags=["540"])
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def language_note(self):
        ruleset = FieldRuleset(tags=["546"])
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def performers(self):
        ruleset = FieldRuleset(tags=["511"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def date_place_of_event(self):
        ruleset = FieldRuleset(tags=["518"], text_sfs="adop23")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def preferred_citation(self):
        ruleset = FieldRuleset(tags=["524"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def location_of_originals(self):
        ruleset = FieldRuleset(tags=["535"], text_sfs=f"{string.ascii_lowercase}3")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def funding_information(self):
        ruleset = FieldRuleset(tags=["536"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def source_of_acquisition(self):
        ruleset = FieldRuleset(tags=["541"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def related_items(self):
        ruleset = FieldRuleset(tags=["580"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def numbering(self):
        ruleset = FieldRuleset(tags=["362"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def current_publication_frequency(self):
        ruleset = FieldRuleset(tags=["310"], text_sfs="ab")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def former_publication_frequency(self):
        ruleset = FieldRuleset(tags=["321"], text_sfs="ab")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def numbering_notes(self):
        ruleset = FieldRuleset(tags=["515"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def source_of_description_note(self):
        ruleset = FieldRuleset(tags=["588"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def copy_specific_note(self):
        ruleset = FieldRuleset(tags=["590"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def references(self):
        ruleset = FieldRuleset(tags=["510"])
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def copyright_status_information(self):
        ruleset = FieldRuleset(tags=["542"])
        return self.processor.generate_paired_fields(tuple([ruleset]))

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
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def arrangement(self):
        ruleset = FieldRuleset(tags=["351"], text_sfs="ab3")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def copyright(self):
        ruleset = FieldRuleset(
            tags=["264"], filter=lambda field: (field.indicator2 == "4")
        )

        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def physical_description(self):
        ruleset = FieldRuleset(tags=["300"])
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def map_scale(self):
        ruleset = FieldRuleset(tags=["255"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def reproduction_note(self):
        ruleset = FieldRuleset(tags=["533"], text_sfs=f"{string.ascii_lowercase}35")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def original_version_note(self):
        ruleset = FieldRuleset(tags=["534"], text_sfs=f"{string.ascii_lowercase}35")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def playing_time(self):
        ruleset = FieldRuleset(tags=["306"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def media_format(self):
        ruleset = FieldRuleset(tags=["538"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def audience(self):
        ruleset = FieldRuleset(tags=["521"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def content_advice(self):
        ruleset = FieldRuleset(
            tags=["520"],
            text_sfs="abc3",
            filter=lambda field: (field.indicator1 == "4"),
        )
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def awards(self):
        ruleset = FieldRuleset(tags=["586"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def production_credits(self):
        ruleset = FieldRuleset(tags=["508"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def bibliography(self):
        ruleset = FieldRuleset(tags=["504"], text_sfs="a")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def publisher_number(self):
        ruleset = FieldRuleset(tags=["028"], text_sfs="ab")
        return self.processor.generate_paired_fields(tuple([ruleset]))

    @property
    def contents(self):
        ruleset = FieldRuleset(tags=["505"])
        return self.processor.generate_paired_fields(tuple([ruleset]))


class BaseRecord(SolrDoc, MARC):
    def __init__(self, data: dict):
        self.data = data
        self.record = pymarc.parse_xml_to_array(io.StringIO(data["fullrecord"]))[0]
        SolrDoc.__init__(self, data)
        MARC.__init__(self, self.record)

    @property
    def marc(self):
        return json.loads(self.record.as_json())

    @property
    def holdings(self):
        holdings_data = json.loads(self.data.get("hol"))
        return Holdings(holdings_data, bib_id=self.id, record=self.record)

class TaggedCitation:
    TAG_MAPPING = [
        {
            "kind": "base",
            "field": "bibliography",
            "ris": ["AB"],
            "meta": ["citation_abstract"],
        },
        {
            "kind": "marc",
            "ruleset": FieldRuleset(
                tags=["100", "101", "110", "111", "700", "710", "711"],
                text_sfs="abcdefgjklnpqtu4",
            ),
            "ris": ["AU"],
            "meta": ["citation_author"],
        },
        {"kind": "base", "field": "series", "ris": ["T3"], "meta": ["series_title"]},
        {"kind": "base", "field": "call_number", "ris": ["CN"], "meta": []},
        {
            "kind": "marc",
            "ruleset": FieldRuleset(
                tags=["260"],
                text_sfs="a",
            ),
            "ris": ["CP", "CY"],
            "meta": [],
        },
        # display_date is from solr. Should use that because it is complicated
        {
            "kind": "marc",
            "ruleset": FieldRuleset(
                tags=["700"],
                text_sfs="ab",
                filter=lambda field: (
                    field.indicator1 == "0" and re.match(field.get("e"), "ed")
                ),
            ),
            "ris": ["CP", "CY"],
            "meta": [],
        },
    ]

    def __init__(self, marc_record, base_record):
        self.processor = Processor(marc_record)
        self.base_record = base_record

    def to_list(self, tag_mapping=TAG_MAPPING):
        result = []
        for element in tag_mapping:
            for x in self._get_result(element):
                result.append(x)

        return result

    def _get_result(self, element):
        if element["kind"] == "base":
            contents = self._get_base_content(element)
        else:
            contents = self._get_marc_content(element)

        return [
            {"content": content, "ris": element["ris"], "meta": element["meta"]}
            for content in contents
        ]

    def _get_base_content(self, element):
        field_content_list = getattr(self.base_record, element["field"])
        return self._get_content(field_content_list)

    def _get_marc_content(self, element):
        field_content_list = self.processor.generate_paired_fields(
            rulesets=[element["ruleset"]]
        )
        return self._get_content(field_content_list)

    def _get_content(self, field_content_list):
        result = []
        for field_value in field_content_list:
            if type(field_value) is str:
                result.append(field_value)
            elif hasattr(field_value, "transliterated") and field_value.transliterated:
                result.append(field_value.transliterated.text)
            elif hasattr(field_value, "original"):
                result.append(field_value.original.text)
            elif hasattr(field_value, "text"):
                result.append(field_value.text)
            else:
                result.append(field_value["text"])
        return result


class Citation:
    def __init__(self, marc_record, base_record):
        self.marc_record = marc_record
        self.base_record = base_record

    @property
    def tagged(self):
        return TaggedCitation(
            marc_record=self.marc_record, base_record=self.base_record
        ).to_list()


class Record(BaseRecord):
    def __init__(self, data: dict):
        self.data = data
        self.record = pymarc.parse_xml_to_array(io.StringIO(data["fullrecord"]))[0]
        BaseRecord.__init__(self, data)

    @property
    def citation(self):
        return Citation(marc_record=self.record, base_record=self)
