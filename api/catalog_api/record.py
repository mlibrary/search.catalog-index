from catalog_api.solr_client import SolrClient


def record_for(id: str):
    data = SolrClient().get_record(id)
    return Record(data)


class Record:
    def __init__(self, data: dict):
        self.data = data
        self.script = ["default", "vernacular"]

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

    def other_titles(self):
        pass

    def _get_solr_paired_field(self, key):
        a = self.data.get(key)
        if a:
            return [
                {"text": element, "script": self.script[index]}
                for index, element in enumerate(a)
            ]
