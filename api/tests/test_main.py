import pytest
from fastapi.testclient import TestClient
from catalog_api.main import app

@pytest.fixture()
def client():
    yield TestClient(app)

@pytest.fixture()
def valid_mms_id():
    return "990040063470106381"

def test_get_record(client, valid_mms_id):
    response = client.get(f"/records/{valid_mms_id}")
    assert response.status_code == 200