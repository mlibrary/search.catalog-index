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
    fields = [
        "title",
        "format",
        "main_author",
        "other_titles",
        "contributors",
        "published",
        "manufactured",
        "edition",
        "series",
    ]

    @pytest.mark.parametrize("field", fields)
    def test_fields_success(self, field, solr_bib, api_output):
        subject = Record(solr_bib)
        assert getattr(subject, field) == api_output[field]

    def test_title_with_only_default_script(self, solr_bib):
        solr_bib["title_display"].pop(1)
        subject = Record(solr_bib)
        assert subject.title[0]["original"]["text"] == solr_bib["title_display"][0]

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
def a_to_z_str():
    return " ".join(list(string.ascii_lowercase))


class TestMARC:
    #####
    # other_titles
    #####

    @pytest.mark.parametrize("tag", ["246", "247", "740"])
    def test_other_titles_246_247_740_with_t_and_indicator_2(self, tag, a_to_z_str):
        record = self.create_record_with_paired_field(tag=tag, ind2="2")
        subject = MARC(record)

        expected = [
            {
                "transliterated": {
                    "text": a_to_z_str,
                    "search": [{"field": "title", "value": a_to_z_str}],
                    "tag": tag,
                },
                "original": {
                    "text": a_to_z_str,
                    "search": [{"field": "title", "value": a_to_z_str}],
                    "tag": "880",
                },
            }
        ]

        assert subject.other_titles == expected

    @pytest.mark.parametrize("tag", ["700", "710", "711"])
    def test_other_titles_700_710_711_with_t_and_indicator_2(self, tag):
        record = self.create_record_with_paired_field(tag=tag, ind2="2")
        subject = MARC(record)
        if tag in ["700", "710"]:
            expected = [
                {
                    "transliterated": {
                        "text": "a b c d e f g j k l m n o p q r s t",
                        "search": [
                            {"field": "title", "value": "f j k l m n o p r s t"}
                        ],
                        "tag": tag,
                    },
                    "original": {
                        "text": "a b c d e f g j k l m n o p q r s t",
                        "search": [
                            {"field": "title", "value": "f j k l m n o p r s t"}
                        ],
                        "tag": "880",
                    },
                }
            ]
        else:  # 711
            expected = [
                {
                    "transliterated": {
                        "text": "a b c d e f g j k l m n o p q r s t",
                        "search": [
                            {"field": "title", "value": "f k l m n o p r s t"}
                        ],  # this does not have a $j
                        "tag": tag,
                    },
                    "original": {
                        "text": "a b c d e f g j k l m n o p q r s t",
                        "search": [
                            {"field": "title", "value": "f k l m n o p r s t"}
                        ],  # this does not have a $j
                        "tag": "880",
                    },
                }
            ]
        assert subject.other_titles == expected

    @pytest.mark.parametrize("tag", ["700", "710", "711"])
    def test_other_titles_700_710_711_with_t_and_no_indicator_2(self, tag):
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = []
        assert subject.other_titles == expected

    @pytest.mark.parametrize("tag", ["700", "710", "711"])
    def test_other_titles_700_710_711_with_indicator_2_and_no_t(self, tag):
        sfs = string.ascii_lowercase.replace("t", "")
        record = self.create_record_with_paired_field(tag=tag, subfields=sfs, ind2="2")
        subject = MARC(record)
        assert subject.other_titles == []

    #####
    # contributors
    #####
    @pytest.mark.parametrize("tag", ["700", "710", "711"])
    def test_contributors_with_indicator_2_not_2_and_no_t(self, tag):
        sfs = string.ascii_lowercase.replace("t", "") + "4"
        record = self.create_record_with_paired_field(tag=tag, subfields=sfs)

        subject = MARC(record)
        expected = [
            {
                "transliterated": {
                    "text": "a b c d e f g j k l n p q u 4",
                    "search": [{"field": "author", "value": "a b c d g j k q u"}],
                    "browse": "a b c d g j k q u",
                    "tag": tag,
                },
                "original": {
                    "text": "a b c d e f g j k l n p q u 4",
                    "search": [{"field": "author", "value": "a b c d g j k q u"}],
                    "browse": "a b c d g j k q u",
                    "tag": "880",
                },
            }
        ]

        assert subject.contributors == expected

    @pytest.mark.parametrize("tag", ["700", "710", "711"])
    def test_contributors_with_indicator_2_not_2_and_t(self, tag):
        sfs = string.ascii_lowercase + "4"
        record = self.create_record_with_paired_field(tag=tag, subfields=sfs)
        subject = MARC(record)
        assert subject.contributors == []

    @pytest.mark.parametrize("tag", ["700", "710", "711"])
    def test_contributors_with_indicator_2_as_2_and_no_t(self, tag):
        sfs = string.ascii_lowercase.replace("t", "") + "4"
        record = self.create_record_with_paired_field(tag=tag, subfields=sfs, ind2="2")
        subject = MARC(record)
        assert subject.contributors == []

    ###
    # manufactured
    ###
    def test_manufactured_260(self):
        record = self.create_record_with_paired_field(tag="260")
        subject = MARC(record)
        expected = [
            {
                "transliterated": {
                    "text": "e f g",
                    "tag": "260",
                },
                "original": {
                    "text": "e f g",
                    "tag": "880",
                },
            }
        ]

        assert subject.manufactured == expected

    def test_manufactured_264_with_indicator2_as_3(self, a_to_z_str):
        record = self.create_record_with_paired_field(tag="264", ind2="3")
        subject = MARC(record)
        expected = [
            {
                "transliterated": {"text": a_to_z_str, "tag": "264"},
                "original": {
                    "text": a_to_z_str,
                    "tag": "880",
                },
            }
        ]

        assert subject.manufactured == expected

    ####
    # series
    ###

    @pytest.mark.parametrize("tag", ["400", "410", "411", "440", "490"])
    def test_series(self, tag, a_to_z_str):
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = [
            {
                "transliterated": {
                    "text": a_to_z_str,
                    "tag": tag,
                },
                "original": {
                    "text": a_to_z_str,
                    "tag": "880",
                },
            }
        ]
        assert subject.series == expected

    def create_record_with_paired_field(
        self,
        tag: str,
        subfields: str = (string.ascii_lowercase + "12345"),
        ind1: str | None = None,
        ind2: str | None = None,
    ):
        record = pymarc.record.Record()
        subfields = [pymarc.Subfield(code=code, value=code) for code in list(subfields)]

        vsubfields = subfields.copy()

        subfields.append(pymarc.Subfield(code="6", value="880-06"))
        vsubfields.append(pymarc.Subfield(code="6", value=f"{tag}-06"))

        field = pymarc.Field(
            tag=tag, indicators=pymarc.Indicators(ind1, ind2), subfields=subfields
        )

        vfield = pymarc.Field(
            tag="880", indicators=pymarc.Indicators(ind1, ind2), subfields=vsubfields
        )

        record.add_field(field)
        record.add_field(vfield)
        return record
