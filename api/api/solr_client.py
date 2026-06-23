import requests
from requests.auth import HTTPBasicAuth
from api.services import S
from api.metrics import SOLR_HISTOGRAM


class NotFoundError(Exception):
    pass


class SolrClient:
    def __init__(self) -> None:
        self.session = requests.Session()
        self.base_url = f"{S.solr_url}/solr/biblio"
        if S.solr_cloud_on:
            self.session.auth = HTTPBasicAuth(S.solr_user, S.solr_password)

    @SOLR_HISTOGRAM.labels(datastore="catalog").time()
    def get_record(self, id: str):
        params = {"q": f"id:{id}"}
        url = f"{self.base_url}/select"
        response = self.session.get(url, params=params)
        if response.json()["response"]["numFound"] == 0:
            raise NotFoundError()
        return response.json()["response"]["docs"][0]

    @SOLR_HISTOGRAM.labels(datastore="onlinejournals").time()
    def get_onlinejournals_record(self, id: str):
        params = {"q": f"id:{id} AND format:Serial AND location:ELEC"}
        url = f"{self.base_url}/select"
        response = self.session.get(url, params=params)
        if response.json()["response"]["numFound"] == 0:
            raise NotFoundError()
        return response.json()["response"]["docs"][0]
