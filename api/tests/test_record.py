import pytest
import json
from catalog_api.record import Record


@pytest.fixture()
def solr_bib():
    bib = {}
    with open("tests/fixtures/land_birds_solr.json") as data:
        bib = json.load(data)
    return bib["response"]["docs"][0]


@pytest.fixture()
def api_output():
    with open("tests/fixtures/land_birds.json") as data:
        return json.load(data)


def test_record_title(solr_bib, api_output):
    subject = Record(solr_bib)
    assert subject.title == api_output["title"]


def test_record_title_with_only_default_script(solr_bib, api_output):
    solr_bib["title_display"].pop(1)
    api_output["title"].pop(1)
    subject = Record(solr_bib)
    assert len(subject.title) == 1


def test_record_title_with_no_title(solr_bib):
    solr_bib.pop("title_display")
    subject = Record(solr_bib)
    assert subject.title is None
