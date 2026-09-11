from prometheus_client import Histogram

ALMA_LOAN_HISTOGRAM = Histogram(
    "search_api_alma_loan_request_duration_seconds",
    "Length of request for alma loan",
)

SOLR_HISTOGRAM = Histogram(
    "search_api_solr_record_request_duration_seconds",
    "Length of solr record requests",
    labelnames=["datastore"],
)

REQUEST_HISTOGRAM = Histogram(
    "search_api_request_duration_seconds",
    "Length of api request for the catalog api app",
    labelnames=["datastore", "route"],
)
