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

    def _get_solr_paired_field(self, key):
        a = self.data.get(key)
        if a:
            return [
                {"text": element, "script": self.script[index]}
                for index, element in enumerate(a)
            ]
