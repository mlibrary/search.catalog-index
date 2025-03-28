from catalog_api.solr_client import SolrClient

def record_for(id: str):
    data = SolrClient().get_record(id)
    return Record(data)


class Record:
    def __init__(self, data: dict):
        self.data = data

    @property
    def id(self):
      return self.data["id"]

    @property
    def title(self):
       return self.data["title_display"]