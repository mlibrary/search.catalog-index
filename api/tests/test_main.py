import responses
import pytest
import json
from fastapi.testclient import TestClient
from api.main import app
from api.services import S


@pytest.fixture()
def solr_bib():
    bib = {}
    with open("tests/fixtures/land_birds_solr.json") as data:
        bib = json.load(data)
    return bib


@pytest.fixture()
def client():
    yield TestClient(app)


@pytest.fixture()
def valid_mms_id():
    return "990008019700106381"


@pytest.fixture
def loan_data():
    return json.loads('{"total_record_count": 0}')


@responses.activate
def test_get_record(client, valid_mms_id, solr_bib, loan_data):
    responses.get(
        f"{S.alma_api_url}/bibs/{valid_mms_id}/loans", json=loan_data, status=200
    )
    responses.get(f"{S.solr_url}/solr/biblio/select", json=solr_bib, status=200)

    with open("tests/fixtures/land_birds.json") as data:
        expected = json.load(data)

    response = client.get(f"/catalog/records/{valid_mms_id}")
    assert response.status_code == 200
    subject = response.json()
    for field in expected:
        assert subject[field] == expected[field]
