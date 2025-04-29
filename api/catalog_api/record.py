from catalog_api.solr_client import SolrClient
import pymarc
import io
import re
import string
from typing import Optional


def record_for(id: str):
    data = SolrClient().get_record(id)
    return Record(data)


class Record:
    def __init__(self, data: dict):
        self.data = data
        self.script = ["default", "vernacular"]
        self.record = pymarc.parse_xml_to_array(io.StringIO(data["fullrecord"]))[0]
        self.marc = MARC(self.record)

    @property
    def id(self):
        return self.data["id"]

    @property
    def title(self):
        return self._get_solr_paired_field("title_display")

    @property
    def format(self):
        return self.data.get("format") or []

    @property
    def main_author(self):
        main = self.data.get("main_author_display") or []
        search = self.data.get("main_author") or []
        return [
            {
                "text": element,
                "script": self.script[index],
                "search": search[index],
                "browse": search[index],
            }
            for index, element in enumerate(main)
        ]

    # TODO: unit tests for all of the options
    @property
    def other_titles(self) -> list:
        return self.marc.other_titles

    @property
    def contributors(self) -> list:
        return self.marc.contributors

    def _get_solr_paired_field(self, key):
        a = self.data.get(key) or []
        return [
            {"text": element, "script": self.script[index]}
            for index, element in enumerate(a)
        ]


class MARC:
    def __init__(self, record: pymarc.record.Record):
        self.record = record

    @property
    def other_titles(self) -> list:
        """
        Could add "tag" and "linkage" to the output to enable matching up parallel fields
        I wouldn't want to fetch any paired fields from solr then though
        """
        result = []
        for field in self._get_paired_fields_for(["246", "247", "740"]):
            result.append(
                self._generate_paired_field(
                    field=field,
                    text_sfs=string.ascii_lowercase,
                    search_sfs=string.ascii_lowercase,
                )
            )

        for field in self._get_paired_fields_for(["700", "710"]):
            if field.get_subfields("t") and field.indicator2 == "2":
                result.append(
                    self._generate_paired_field(
                        field=field,
                        text_sfs="abcdefgjklmnopqrst",
                        search_sfs="fkjlmnoprst",
                    )
                )

        for field in self._get_paired_fields_for(["711"]):
            if field.get_subfields("t") and field.indicator2 == "2":
                result.append(
                    self._generate_paired_field(
                        field=field,
                        text_sfs="abcdefgjklmnopqrst",
                        search_sfs="fklmnoprst",  # no j subfield
                    )
                )

        return result

    @property
    def contributors(self):
        result = []
        contributor_fields = (
            field
            for field in self._get_paired_fields_for(["700", "710", "711"])
            if not field.get_subfields("t") and field.indicator2 != "2"
        )
        text_sfs = "abcdefgjklnpqu4"
        search_sfs = "abcdgjkqu"

        for field in contributor_fields:
            result.append(
                self._generate_paired_field(
                    field=field,
                    text_sfs=text_sfs,
                    search_sfs=search_sfs,
                    browse_sfs=search_sfs,
                )
            )

        return result

    def _get_subfields(self, field: pymarc.Field, subfields: str):
        return " ".join(field.get_subfields(*tuple(subfields)))

    def _get_vernacular_for_tags(self, tags: tuple) -> list:
        def linkage_has_tag(field):
            return Linkage(field).tag in tags

        return list(filter(linkage_has_tag, self.record.get_fields("880")))

    def _get_paired_fields_for(self, tags: tuple) -> list:
        return self.record.get_fields(*tags) + self._get_vernacular_for_tags(tags)

    def _generate_paired_field(
        self,
        field: pymarc.Field,
        text_sfs: str,
        search_sfs: Optional[str] = None,
        browse_sfs: Optional[str] = None,
    ):
        result = {
            "script": "vernacular" if field.tag == "880" else "default",
            "text": self._get_subfields(field, text_sfs),
            "tag": field.tag,
            "linkage": Linkage(field).as_dict(),
        }

        if search_sfs:
            result["search"] = self._get_subfields(field, search_sfs)

        if browse_sfs:
            result["browse"] = self._get_subfields(field, browse_sfs)

        return result


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

    def as_dict(self):
        if self.tag:
            return {"tag": self.tag, "occurence_number": self.occurence_number}
        else:
            None
