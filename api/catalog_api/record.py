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
        self.script = ["transliterated", "original"]
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

        match len(main):
            case 0:
                return []
            case 1:
                return [
                    {
                        "original": {
                            "text": main[0],
                            "search": {"author": search[0]},
                            "browse": search[0],
                        }
                    }
                ]
            case _:
                return [
                    {
                        "transliterated": {
                            "text": main[0],
                            "search": {"author": search[0]},
                            "browse": search[0],
                        },
                        "original": {
                            "text": main[1],
                            "search": {"author": search[1]},
                            "browse": search[1],
                        },
                    }
                ]

    # TODO: unit tests for all of the options
    @property
    def other_titles(self) -> list:
        return self.marc.other_titles

    @property
    def contributors(self) -> list:
        return self.marc.contributors

    @property
    def published(self) -> list:
        return self._get_solr_paired_field("publisher_display")

    @property
    def manufactured(self) -> list:
        return self.marc.manufactured

    @property
    def edition(self) -> list:
        return self._get_solr_paired_field("edition")

    @property
    def series(self) -> list:
        return self.marc.series

    def _get_solr_paired_field(self, key):
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
    def other_titles(self) -> list:
        """
        Could add "tag" and "linkage" to the output to enable matching up parallel fields
        I wouldn't want to fetch any paired fields from solr then though
        """
        result = []
        for fields in self._get_BETTER_pf_for(["246", "247", "740"]):
            result.append(
                self._generate_GREAT_pf(
                    fields=fields,
                    search_sfs=string.ascii_lowercase,
                    search_field="title",
                )
            )

        for fields in self._get_BETTER_pf_for(["700", "710"]):
            if (
                fields["original"].get_subfields("t")
                and fields["original"].indicator2 == "2"
            ):
                result.append(
                    self._generate_GREAT_pf(
                        fields=fields,
                        text_sfs="abcdefgjklmnopqrst",
                        search_sfs="fkjlmnoprst",
                        search_field="title",
                    )
                )

        for fields in self._get_BETTER_pf_for(["711"]):
            if (
                fields["original"].get_subfields("t")
                and fields["original"].indicator2 == "2"
            ):
                result.append(
                    self._generate_GREAT_pf(
                        fields=fields,
                        text_sfs="abcdefgjklmnopqrst",
                        search_sfs="fklmnoprst",  # no j subfield
                        search_field="title",
                    )
                )

        return result

    @property
    def contributors(self):
        result = []
        contributor_fields = (
            fields
            for fields in self._get_BETTER_pf_for(["700", "710", "711"])
            if not fields["original"].get_subfields("t")
            and fields["original"].indicator2 != "2"
        )
        text_sfs = "abcdefgjklnpqu4"
        search_sfs = "abcdgjkqu"

        for fields in contributor_fields:
            result.append(
                self._generate_GREAT_pf(
                    fields=fields,
                    text_sfs=text_sfs,
                    search_sfs=search_sfs,
                    search_field="author",
                    browse_sfs=search_sfs,
                )
            )

        return result

    @property
    def manufactured(self):
        result = []
        for fields in self._get_BETTER_pf_for(["260"]):
            result.append(self._generate_GREAT_pf(fields=fields, text_sfs="efg"))

        for fields in self._get_BETTER_pf_for(["264"]):
            if fields["original"].indicator2 == "3":
                result.append(self._generate_GREAT_pf(fields=fields))
        return result

    @property
    def series(self):
        result = []
        for fields in self._get_BETTER_pf_for(["400", "410", "411", "440", "490"]):
            result.append(self._generate_GREAT_pf(fields=fields))
        return result

    def _get_subfields(self, field: pymarc.Field, subfields: str):
        return " ".join(field.get_subfields(*tuple(subfields)))

    def _get_original_for_tags(self, tags: tuple) -> list:
        def linkage_has_tag(field):
            return Linkage(field).tag in tags

        return list(filter(linkage_has_tag, self.record.get_fields("880")))

    def _get_paired_fields_for(self, tags: tuple) -> list:
        return self.record.get_fields(*tags) + self._get_original_for_tags(tags)

    def _get_BETTER_pf_for(self, tags: tuple) -> list:
        mapping = {}
        for field in self._get_original_for_tags(tags):
            mapping[Linkage(field).__str__()] = field

        results = []
        for field in self.record.get_fields(*tags):
            original = mapping.pop(
                f"{field.tag}-{Linkage(field).occurence_number}", None
            )
            if original:
                results.append({"transliterated": field, "original": original})
            else:
                results.append({"original": field})

        return results + list(mapping.values())

    def _generate_paired_field(
        self,
        field: pymarc.Field,
        text_sfs: str = string.ascii_lowercase,
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

    def _generate_GREAT_pf(
        self,
        fields: dict,
        text_sfs: str = string.ascii_lowercase,
        search_sfs: Optional[str] = None,
        search_field: Optional[str] = None,
        browse_sfs: Optional[str] = None,
    ):
        result = {}
        for key in fields.keys():
            result[key] = self._generate_AWESOME_pf_field(
                field=fields[key],
                text_sfs=text_sfs,
                search_sfs=search_sfs,
                search_field=search_field,
                browse_sfs=browse_sfs,
            )
        return result

    def _generate_AWESOME_pf_field(
        self,
        field: pymarc.Field,
        text_sfs: str = string.ascii_lowercase,
        search_sfs: Optional[str] = None,
        search_field: Optional[str] = None,
        browse_sfs: Optional[str] = None,
    ):
        result = {
            "text": self._get_subfields(field, text_sfs),
            "tag": field.tag,
        }

        if search_sfs:
            result["search"] = {search_field: self._get_subfields(field, search_sfs)}

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

    def __str__(self):
        return f"{self.tag}-{self.occurence_number}"

    def as_dict(self):
        if self.tag:
            return {"tag": self.tag, "occurence_number": self.occurence_number}
        else:
            None
