from catalog_api.solr_client import SolrClient
import pymarc
import io
import string


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
        result = []
        for field in self.record.get_fields("246", "247", "740"):
            text = self._get_subfields(field, string.ascii_lowercase)
            result.append({"script": "default", "text": text, "search": text})

        for field in self.record.get_fields("700", "710", "711"):
            if field.get_subfields("t") and field.indicator2 == "2":
                search_sf = "fklmnoprst" if field.tag == "711" else "fjklmnoprst"
                text = self._get_subfields(field, "abcdefgjklmnopqrst")
                search = self._get_subfields(field, search_sf)
                result.append({"text": text, "search": search})

        for field in self.record.get_fields("880"):
            if any(
                sf.startswith(("246", "247", "740")) for sf in field.get_subfields("6")
            ):
                text = self._get_subfields(field, string.ascii_lowercase)
                result.append({"script": "vernacular", "text": text, "search": text})

        return result

    @property
    def contributors(self):
        result = []
        tags = ["700", "710", "711"]
        for field in self.record.get_fields(*tags):
            text = self._get_subfields(field, "abcdefgjklnpqu4")
            search = self._get_subfields(field, "abcdgjkqu")
            result.append(
                {"script": "default", "text": text, "search": search, "browse": search}
            )

        for field in self.record.get_fields("880"):
            if any(sf.startswith(tuple(tags)) for sf in field.get_subfields("6")):
                text = self._get_subfields(field, "abcdefgjklnpqu4")
                search = self._get_subfields(field, "abcdgjkqu")

                result.append(
                    {
                        "script": "vernacular",
                        "text": text,
                        "search": search,
                        "browse": search,
                    }
                )

        return result

    def _get_subfields(self, field: pymarc.Field, subfields: str):
        return " ".join(field.get_subfields(*list(subfields)))
