import requests
from requests.auth import HTTPBasicAuth
from catalog_api.services import S
from prometheus_client import Histogram


class NotFoundError(Exception):
    pass


class SolrClient:
    SOLR_HISTOGRAM = Histogram(
        "solr_catalog_record_request_duration_seconds", "Length of solr requests"
    )

    def __init__(self) -> None:
        self.session = requests.Session()
        self.base_url = f"{S.solr_url}/solr/biblio"
        if S.solr_cloud_on:
            self.session.auth = HTTPBasicAuth(S.solr_user, S.solr_password)

    @SOLR_HISTOGRAM.time()
    def get_record(self, id: str):
        params = {"q": f"id:{id}"}
        url = f"{self.base_url}/select"
        response = self.session.get(url, params=params)
        if response.json()["response"]["numFound"] == 0:
            raise NotFoundError()
        return response.json()["response"]["docs"][0]
