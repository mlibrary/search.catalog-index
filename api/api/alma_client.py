import requests
from api.services import S
from prometheus_client import Histogram
import xml.etree.ElementTree as ET


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
        total = 0
        result = {"item_loan": [], "total_record_count": 0}

        try:
            response = self.session.get(url, params={"limit": limit})
            response.raise_for_status()
            result = response.json()
            total = result["total_record_count"]
        except requests.exceptions.HTTPError as e:
            S.logger.error(
                f"HTTP error occurred: {e} {self.get_alma_error_string(response.text)}"
            )
        except requests.exceptions.RequestException as e:
            S.logger.error("A request error occurred:", e)

        if total > 100:
            while total > offset + limit:
                offset = offset + limit
                response = self.session.get(
                    url, params={"limit": limit, "offset": offset}
                )
                for loan in response.json().get("item_loan", []):
                    result["item_loan"].append(loan)

        if "item_loan" not in result:
            result["item_loan"] = []

        return result

    def get_alma_error_string(self, error_string):
        ns = {"alma": "http://com/exlibris/urm/general/xmlbeans"}
        root = ET.fromstring(error_string)
        result = []
        for error in root.findall(".//alma:error", ns):
            code = error.find("alma:errorCode", ns)
            message = error.find("alma:errorMessage", ns)
            result.append(f"code: {code.text}, message: {message.text}")

        return " | ".join(result)
