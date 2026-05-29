import requests
from requests.auth import HTTPBasicAuth
from api.services import S
from prometheus_client import Histogram


class NotFoundError(Exception):
    pass


class AlmaClient:
    ALMA_LOAN_HISTOGRAM = Histogram(
        "catalog_api_alma_loan_request_duration_seconds",
        "Length of request for alma loan",
    )

    base_url = S.alma_api_url

    def __init__(self) -> None:
        self.session = requests.Session()
        self.session.headers.update(
            {
                "Authorization": f"apikey {S.alma_api_key}",
                "Accept": "application/json",
                "Content-Type": "application/json",
            }
        )

    @ALMA_LOAN_HISTOGRAM.time()
    def get_loans(self, mms_id: str):
        limit = 100
        offset = 0
        url = f"{self.base_url}/bibs/{mms_id}/loans"

        response = self.session.get(url, params={"limit": limit})
        total = response.json()["total_record_count"]

        result = response.json()

        if total > 100:
            while total > offset + limit:
                offset = offset + limit
                response = self.session.get(
                    url, params={"limit": limit, "offset": offset}
                )
                for loan in response.json()["item_loan"]:
                    result["item_loan"].append(loan)

        return result
