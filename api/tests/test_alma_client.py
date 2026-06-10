import responses
import pytest
import json
from api.alma_client import AlmaClient
from api.services import S


@pytest.fixture()
def loan():
    loan = None
    with open("tests/fixtures/loans/alma_loans_example.json") as data:
        loan = json.load(data)
    return loan


@pytest.fixture
def empty_loan_data():
    return json.loads('{"total_record_count": 0}')


@pytest.fixture()
def mms_id(loan):
    return loan["item_loan"][0]["mms_id"]


@responses.activate
def test_alma_client_get_loans_gets_one_page(loan, mms_id):
    responses.get(
        f"{S.alma_api_url}/bibs/{mms_id}/loans?limit=100", json=loan, status=200
    )

    assert AlmaClient().get_loans(mms_id) == loan


@responses.activate
def test_alma_client_get_loans_gets_all_results(loan, mms_id):
    loan["total_record_count"] = 101

    responses.get(
        f"{S.alma_api_url}/bibs/{mms_id}/loans?limit=100", json=loan, status=200
    )

    responses.get(
        f"{S.alma_api_url}/bibs/{mms_id}/loans?limit=100&offset=100",
        json=loan,
        status=200,
    )
    loans = AlmaClient().get_loans(mms_id)
    assert len(loans["item_loan"]) == 2


@responses.activate
def test_alma_client_get_loans_handles_no_loans(empty_loan_data, mms_id):
    responses.get(
        f"{S.alma_api_url}/bibs/{mms_id}/loans?limit=100",
        json=empty_loan_data,
        status=200,
    )
    loans = AlmaClient().get_loans(mms_id)
    assert len(loans["item_loan"]) == 0
