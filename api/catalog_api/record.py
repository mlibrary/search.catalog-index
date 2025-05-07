from catalog_api.solr_client import SolrClient
import pymarc
import io
import re
import string
from typing import Optional
from dataclasses import dataclass
from collections.abc import Callable


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


@dataclass(frozen=True)
class DataClump:
    tags: list
    text_sfs: str = string.ascii_lowercase
    search_sfs: str | None = None
    search_field: str | None = None
    browse_sfs: str | None = None
    filter: Callable[..., bool] = lambda field: True


class MARC:
    def __init__(self, record: pymarc.record.Record):
        self.record = record

    @property
    def other_titles(self) -> list:
        """
        Could add "tag" and "linkage" to the output to enable matching up parallel fields
        I wouldn't want to fetch any paired fields from solr then though
        """

        def is_a_title(field: pymarc.Field) -> bool:
            return field.get_subfields("t") and field.indicator2 == "2"

        result = []
        data = [
            DataClump(
                tags=["246", "247", "740"],
                search_sfs=string.ascii_lowercase,
                search_field="title",
            ),
            DataClump(
                tags=["700", "710"],
                text_sfs="abcdefgjklmnopqrst",
                search_sfs="fkjlmnoprst",
                search_field="title",
                filter=is_a_title,
            ),
            DataClump(
                tags=["711"],
                text_sfs="abcdefgjklmnopqrst",
                search_sfs="fklmnoprst",  # no j subfield
                search_field="title",
                filter=is_a_title,
            ),
        ]

        for datum in data:
            for fields in self._get_paired_fields_for(datum):
                if datum.filter(fields["original"]):
                    result.append(
                        self._generate_paired_field(fields=fields, data=datum)
                    )

        return result

    @property
    def contributors(self):
        result = []
        search_sfs = "abcdgjkqu"
        clump = DataClump(
            tags=["700", "710", "711"],
            text_sfs="abcdefgjklnpqu4",
            search_sfs=search_sfs,
            search_field="author",
            browse_sfs=search_sfs,
            filter=lambda field: (
                not field.get_subfields("t") and fields["original"].indicator2 != "2"
            ),
        )

        for fields in self._get_paired_fields_for(clump):
            if clump.filter(fields["original"]):
                result.append(self._generate_paired_field(fields=fields, data=clump))

        return result

    @property
    def manufactured(self):
        result = []
        data = [
            DataClump(tags=["260"], text_sfs="efg"),
            DataClump(tags=["264"], filter=lambda field: (field.indicator2 == "3")),
        ]

        for datum in data:
            for fields in self._get_paired_fields_for(datum):
                if datum.filter(fields["original"]):
                    result.append(
                        self._generate_paired_field(fields=fields, data=datum)
                    )
        return result

    @property
    def series(self):
        result = []
        clump = DataClump(tags=["400", "410", "411", "440", "490"])
        for fields in self._get_paired_fields_for(clump):
            if clump.filter(fields["original"]):
                result.append(self._generate_paired_field(fields=fields, data=clump))
        return result

    def _get_subfields(self, field: pymarc.Field, subfields: str):
        return " ".join(field.get_subfields(*tuple(subfields)))

    def _get_original_for_tags(self, tags: tuple) -> list:
        def linkage_has_tag(field):
            return Linkage(field).tag in tags

        return list(filter(linkage_has_tag, self.record.get_fields("880")))

    def _get_paired_fields_for(self, data: DataClump) -> list:
        mapping = {}
        for field in self._get_original_for_tags(data.tags):
            mapping[Linkage(field).__str__()] = field

        results = []
        for field in self.record.get_fields(*data.tags):
            if self._get_subfields(field, data.text_sfs):
                original = mapping.pop(
                    f"{field.tag}-{Linkage(field).occurence_number}", None
                )
                if original:
                    results.append({"transliterated": field, "original": original})
                else:
                    results.append({"original": field})

        return results + [
            {"original": f}
            for f in mapping.values()
            if self._get_subfields(f, data.text_sfs)
        ]

    def _generate_paired_field(
        self,
        fields: dict,
        text_sfs: str = string.ascii_lowercase,
        search_sfs: Optional[str] = None,
        search_field: Optional[str] = None,
        browse_sfs: Optional[str] = None,
        data: DataClump | None = None,
    ):
        result = {}
        if data:
            text_sfs = data.text_sfs
            search_sfs = data.search_sfs
            search_field = data.search_field
            browse_sfs = data.browse_sfs

        for key in fields.keys():
            field = fields[key]
            output = {
                "text": self._get_subfields(field, text_sfs),
                "tag": field.tag,
            }

            if search_sfs:
                output["search"] = [
                    {
                        "field": search_field,
                        "value": self._get_subfields(field, search_sfs),
                    }
                ]

            if browse_sfs:
                output["browse"] = self._get_subfields(field, browse_sfs)

            result[key] = output
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
