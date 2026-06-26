from dataclasses import dataclass
import logging
import os


@dataclass(frozen=True)
class Services:
    """
    Global Configuration Services
    """

    solr_url: str
    website_solr_url: str
    solr_cloud_on: bool
    solr_user: str
    solr_password: str
    parser_url: str
    alma_api_url: str
    primo_api_url: str
    alma_api_key: str
    logger: logging.Logger


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)


S = Services(
    solr_url=os.getenv("SOLR_URL") or "http://solr:8983",
    website_solr_url=os.getenv("WEBSITE_SOLR_URL") or "http://website-solr:8983",
    solr_cloud_on=os.getenv("SOLR_CLOUD_ON") == "true",
    solr_user=os.getenv("SOLR_USER") or "solr",
    solr_password=os.getenv("SOLR_PASSWORD") or "SolrRocks",
    parser_url=os.getenv("PARSER_URL") or "http://parser:4567",
    alma_api_url="https://api-na.hosted.exlibrisgroup.com/almaws/v1",
    primo_api_url="https://api-na.hosted.exlibrisgroup.com/primo/v1",
    alma_api_key=os.getenv("ALMA_API_KEY") or "your_alma_api_key",
    logger=logging.getLogger(__name__),
)
