from dataclasses import dataclass
import os
@dataclass(frozen=True)
class Services:
    """
    Global Configuration Services
    """

    solr_url: str
    solr_cloud_on: bool
    solr_user: str
    solr_password: str


S = Services(
    solr_url=os.getenv("SOLR_URL") or "http://solr:8983",
    solr_cloud_on=os.getenv("SOLR_CLOUD_ON") == "true",
    solr_user=os.getenv("SOLR_USER") or "solr",
    solr_password=os.getenv("SOLR_PASSWORD") or "SolrRocks"
)