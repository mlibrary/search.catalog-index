import requests
from requests.auth import HTTPBasicAuth
from catalog_api.services import S


class NotFoundError(Exception):
    pass


class SolrClient:
    def __init__(self) -> None:
        self.session = requests.Session()
        self.base_url = f"{S.solr_url}/solr/biblio"
        if S.solr_cloud_on:
            self.session.auth = HTTPBasicAuth(S.solr_user, S.solr_password)

    def get_record(self, id: str):
        params = {"q": f"id:{id}"}
        url = f"{self.base_url}/select"
        response = self.session.get(url, params=params)
        if response.json()["response"]["numFound"] == 0:
            raise NotFoundError()
        return response.json()["response"]["docs"][0]
