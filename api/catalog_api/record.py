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

    @property
    def id(self):
        return self.data["id"]

    @property
    def title(self):
        return self._get_solr_paired_field("title_display")

    @property
    def format(self):
        return self.data.get("format")

    @property
    def main_author(self):
        main = self.data.get("main_author_display")
        search = self.data.get("main_author")
        if main and search:
            return [
                {
                    "text": element,
                    "script": self.script[index],
                    "search": search[index],
                    "browse": search[index],
                }
                for index, element in enumerate(main)
            ]

    @property
    def other_titles(self):
        result = []
        for field in self.record.get_fields("246", "247", "740"):
            text = " ".join(field.get_subfields(*list(string.ascii_lowercase)))
            result.append({"text": text, "search": text})
        return result

    def _get_solr_paired_field(self, key):
        a = self.data.get(key)
        if a:
            return [
                {"text": element, "script": self.script[index]}
                for index, element in enumerate(a)
            ]
