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


fields = ["title", "format", "main_author", "other_titles"]


@pytest.mark.parametrize("field", fields)
def test_record_fields_success(field, solr_bib, api_output):
    subject = Record(solr_bib)
    assert getattr(subject, field) == api_output[field]


def test_record_title_with_only_default_script(solr_bib, api_output):
    solr_bib["title_display"].pop(1)
    api_output["title"].pop(1)
    subject = Record(solr_bib)
    assert len(subject.title) == 1


def test_record_title_with_no_title(solr_bib):
    solr_bib.pop("title_display")
    subject = Record(solr_bib)
    assert subject.title is None


def test_record_formats_with_no_formats(solr_bib):
    solr_bib.pop("format")
    subject = Record(solr_bib)
    assert subject.format is None


def test_record_main_author_no_vernacular(solr_bib):
    solr_bib["main_author"].pop(1)
    solr_bib["main_author_display"].pop(1)
    subject = Record(solr_bib)
    assert len(subject.main_author) == 1


def test_record_with_no_main_author(solr_bib):
    solr_bib.pop("main_author_display")
    subject = Record(solr_bib)
    assert subject.main_author is None
