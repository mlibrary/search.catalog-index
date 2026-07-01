import requests
from urllib.parse import quote
from api.services import S


class LibKeyClient:
    def __init__(self) -> None:
        self.session = requests.Session()
        self.session.headers.update(
            {
                "Authorization": f"Bearer {S.lib_key_key}",
                "Accept": "application/json",
                "Content-Type": "application/json",
            }
        )

    def get_article(self, kind, value):
        url = f"{S.lib_key_host}/public/v1/libraries/{S.lib_key_library_id}/articles/{kind}/{quote(value)}"
        try:
            response = self.session.get(url, timeout=0.5)
            response.raise_for_status()
            body = response.json()
            return body["data"]
        except requests.exceptions.HTTPError as e:
            S.logger.error(f"HTTP error occurred: {e}")
            return None
        except requests.exceptions.RequestException as e:
            S.logger.error(f"A request error occurred: {e}")
            return None
