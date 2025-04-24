import pytest
import json
import pymarc
import string
from catalog_api.record import Record, MARC


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


class TestRecord:
    fields = ["title", "format", "main_author", "other_titles"]

    @pytest.mark.parametrize("field", fields)
    def test_fields_success(self, field, solr_bib, api_output):
        subject = Record(solr_bib)
        assert getattr(subject, field) == api_output[field]

    def test_title_with_only_default_script(self, solr_bib, api_output):
        solr_bib["title_display"].pop(1)
        api_output["title"].pop(1)
        subject = Record(solr_bib)
        assert len(subject.title) == 1

    def test_title_with_no_title(self, solr_bib):
        solr_bib.pop("title_display")
        subject = Record(solr_bib)
        assert subject.title == []

    def test_formats_with_no_formats(self, solr_bib):
        solr_bib.pop("format")
        subject = Record(solr_bib)
        assert subject.format == []

    def test_main_author_no_vernacular(self, solr_bib):
        solr_bib["main_author"].pop(1)
        solr_bib["main_author_display"].pop(1)
        subject = Record(solr_bib)
        assert len(subject.main_author) == 1

    def test_with_no_main_author(self, solr_bib):
        solr_bib.pop("main_author_display")
        subject = Record(solr_bib)
        assert subject.main_author == []


@pytest.fixture()
def marc():
    return pymarc.record.Record()


@pytest.fixture()
def a_to_z_sfs():
    return [
        pymarc.Subfield(code=code, value=code) for code in list(string.ascii_lowercase)
    ]


class TestMARC:
    @pytest.mark.parametrize("tag", ["700", "710"])
    def test_other_titles_700_710_with_t_and_indicator_2(self, tag, marc, a_to_z_sfs):
        field = pymarc.Field(
            tag=tag,
            indicators=pymarc.Indicators("0", "2"),
            subfields=a_to_z_sfs,
        )

        marc.add_field(field)
        subject = MARC(marc)
        expected = [
            {
                "text": "a b c d e f g j k l m n o p q r s t",
                "search": "f j k l m n o p r s t",
            },
        ]
        assert subject.other_titles == expected

    @pytest.mark.parametrize("tag", ["700", "710"])
    def test_other_titles_700_710_with_t_and_no_indicator_2(
        self, tag, marc, a_to_z_sfs
    ):
        field = pymarc.Field(
            tag=tag,
            indicators=pymarc.Indicators("0", "1"),
            subfields=a_to_z_sfs,
        )

        marc.add_field(field)
        subject = MARC(marc)
        expected = []
        assert subject.other_titles == expected

    @pytest.mark.parametrize("tag", ["700", "710"])
    def test_other_titles_700_710_with_indicator_2_and_no_t(
        self, tag, marc, a_to_z_sfs
    ):
        subfields = [x for x in a_to_z_sfs if x.code != "t"]
        field = pymarc.Field(
            tag=tag, indicators=pymarc.Indicators("0", "2"), subfields=subfields
        )

        marc.add_field(field)
        subject = MARC(marc)
        expected = []
        assert subject.other_titles == expected
