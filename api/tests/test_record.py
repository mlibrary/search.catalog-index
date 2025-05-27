import pytest
import json
import pymarc
import string
from catalog_api.record import Record, MARC, SolrDoc, FieldElement
from dataclasses import asdict


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
        "format",
        "language",
        "isbn",
        "call_number",
        "oclc",
        "lc_subjects",
        "academic_discipline",
        "availability",
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

    def test_language_with_no_lanugages(self, solr_bib):
        solr_bib.pop("language")
        subject = Record(solr_bib)
        assert subject.language == []

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

    def test_with_no_academic_disciplines(self, solr_bib):
        solr_bib.pop("hlb3Delimited")
        subject = Record(solr_bib)
        assert subject.academic_discipline == []


class TestSolrDoc:
    def test_title(self, solr_bib):
        subject = SolrDoc(solr_bib)
        assert subject.title == [
            {
                "transliterated": {
                    "text": "Sanʼya no tori = Concise field guide to land birds / kaisetsu Saeki Akimitsu ; e Taniguchi Takashi."
                },
                "original": {
                    "text": "山野の鳥 = Concise field guide to land birds / 解說佐伯彰光 ; 絵谷口高司."
                },
            }
        ]

    def test_issn(self, solr_bib):
        solr_bib["issn"] = ["some_issn"]
        subject = SolrDoc(solr_bib)
        assert subject.issn == [{"text": "some_issn"}]

    def test_gov_doc_number(self, solr_bib):
        solr_bib["sudoc"] = ["some_gov_doc_number"]
        subject = SolrDoc(solr_bib)
        assert subject.gov_doc_number == [{"text": "some_gov_doc_number"}]

    def test_report_number(self, solr_bib):
        solr_bib["rptnum"] = ["some_report_number"]
        subject = SolrDoc(solr_bib)
        assert subject.report_number == [{"text": "some_report_number"}]

    def test_remediated_lc_subjects(self, solr_bib):
        solr_bib["remediated_lc_subject_display"] = ["some -- subject"]
        subject = SolrDoc(solr_bib)
        assert subject.remediated_lc_subjects == [{"text": "some -- subject"}]

    def test_other_subjects(self, solr_bib):
        solr_bib["non_lc_subject_display"] = ["some -- subject"]
        subject = SolrDoc(solr_bib)
        assert subject.other_subjects == [{"text": "some -- subject"}]

    def test_bookplate(self, solr_bib):
        solr_bib["bookplate"] = ["bookplate"]
        subject = SolrDoc(solr_bib)
        assert subject.bookplate == [{"text": "bookplate"}]

    def test_indexing_date(self, solr_bib):
        solr_bib["date_of_index"] = "some_valid_date_string"
        subject = SolrDoc(solr_bib)
        assert subject.indexing_date == "some_valid_date_string"

    def test_main_author(self, solr_bib):
        subject = SolrDoc(solr_bib)
        assert subject.main_author == [
            {
                "transliterated": {
                    "text": "Saeki, Akimitsu.",
                    "search": [{"field": "author", "value": "Saeki, Akimitsu."}],
                    "browse": "Saeki, Akimitsu.",
                },
                "original": {
                    "text": "佐伯彰光.",
                    "search": [{"field": "author", "value": "佐伯彰光."}],
                    "browse": "佐伯彰光.",
                },
            }
        ]

    def test_published(self, solr_bib):
        subject = SolrDoc(solr_bib)
        assert subject.published == [
            {
                "transliterated": {
                    "text": "Tōkyō : Nihon Yachō no Kai, 1983",
                },
                "original": {"text": "東京 : 日本野鳥の会, 1983"},
            }
        ]

    def test_edition(self, solr_bib):
        subject = SolrDoc(solr_bib)
        assert subject.edition == [
            {
                "transliterated": {"text": "3-teiban."},
                "original": {"text": "3訂版."},
            }
        ]


@pytest.fixture()
def a_to_z_str():
    return " ".join(list(string.ascii_lowercase))


class TestMARC:
    ###################
    # preferred_title #
    ###################
    @pytest.mark.parametrize("tag", ["130", "240", "243"])
    def test_preferred_title_130_240_243(self, tag, a_to_z_str):
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={
                "text": a_to_z_str,
                "search": [
                    {
                        "field": "title",
                        "value": "a b c d e f g h i j k m n o p q r s t u v w x y z",  # missing an l
                    }
                ],
            },
        )

        assert serialize(subject.preferred_title) == expected

    def test_preferred_title_730(self):
        record = self.create_record_with_paired_field(tag="730", ind2="2")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="730",
            elements={
                "text": "a b c d e f g h j k l m n o p q r s t u v w x y z",
                "search": [
                    {
                        "field": "title",
                        "value": "a b c d e f g h j k l m n o p q r s t u v w x y z",  # missing an i
                    }
                ],
            },
        )

        assert serialize(subject.preferred_title) == expected

    def test_preferred_title_730_no_ind2(self):
        record = self.create_record_with_paired_field(tag="730", ind2="1")
        subject = MARC(record)
        assert (subject.preferred_title) == []

    #################
    # related_title #
    #################

    def test_related_title_730_blank_ind2(self):
        record = self.create_record_with_paired_field(tag="730", ind2=None)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="730",
            elements={
                "text": "a b c d e f g h j k l m n o p q r s t u v w x y z",
                "search": [
                    {
                        "field": "title",
                        "value": "a b c d e f g h j k l m n o p q r s t u v w x y z",  # missing an i
                    }
                ],
            },
        )
        assert serialize(subject.related_title) == expected

    def test_related_title_730_present_ind2(self):
        record = self.create_record_with_paired_field(tag="730", ind2="1")
        subject = MARC(record)
        assert (subject.related_title) == []

    @pytest.mark.parametrize("tag", ["700", "710"])
    def test_related_title_700_710_ind2_not_2_and_t(self, tag):
        record = self.create_record_with_paired_field(tag=tag, ind2="1")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={
                "text": "a b c d e f g j k l m n o p q r s t",
                "search": [
                    {
                        "field": "title",
                        "value": "f j k l m n o p r s t",
                    }
                ],
            },
        )

        assert serialize(subject.related_title) == expected

    def test_related_title_711_ind2_not_2_and_t(self):
        record = self.create_record_with_paired_field(tag="711", ind2="1")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="711",
            elements={
                "text": "a b c d e f g j k l m n o p q r s t",
                "search": [
                    {
                        "field": "title",
                        "value": "f k l m n o p r s t",
                    }
                ],
            },
        )
        assert serialize(subject.related_title) == expected

    @pytest.mark.parametrize("tag", ["700", "710", "711"])
    def test_related_title_ind2_not_2_no_t(self, tag):
        no_t = string.ascii_lowercase.replace("t", "")
        record = self.create_record_with_paired_field(tag=tag, ind2="2", subfields=no_t)
        subject = MARC(record)
        assert (subject.related_title) == []

    @pytest.mark.parametrize("tag", ["700", "710", "711"])
    def test_related_title_ind2_and_t(self, tag):
        record = self.create_record_with_paired_field(tag=tag, ind2="2")
        subject = MARC(record)
        assert (subject.related_title) == []

    ################
    # other_titles #
    ################

    @pytest.mark.parametrize("tag", ["246", "247", "740"])
    def test_other_titles_246_247_740_with_t_and_indicator_2(self, tag, a_to_z_str):
        record = self.create_record_with_paired_field(tag=tag, ind2="2")
        subject = MARC(record)

        expected = self.expected_paired_field(
            tag=tag,
            elements={
                "text": a_to_z_str,
                "search": [{"field": "title", "value": a_to_z_str}],
            },
        )

        assert serialize(subject.other_titles) == expected

    @pytest.mark.parametrize("tag", ["700", "710", "711"])
    def test_other_titles_700_710_711_with_t_and_indicator_2(self, tag):
        record = self.create_record_with_paired_field(tag=tag, ind2="2")
        subject = MARC(record)
        if tag in ["700", "710"]:
            expected = self.expected_paired_field(
                tag=tag,
                elements={
                    "text": "a b c d e f g j k l m n o p q r s t",
                    "search": [{"field": "title", "value": "f j k l m n o p r s t"}],
                },
            )
        else:  # 711
            expected = self.expected_paired_field(
                tag=tag,
                elements={
                    "text": "a b c d e f g j k l m n o p q r s t",
                    "search": [
                        {"field": "title", "value": "f k l m n o p r s t"}
                    ],  # this does not have a $j
                },
            )
        assert serialize(subject.other_titles) == expected

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

    ##############
    # new_title #
    ##############
    def test_new_title(self):
        record = self.create_record_with_paired_field(tag="785")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="785",
            elements={
                "text": "a s t",
                "search": [
                    {"field": "author", "value": "a"},
                    {"field": "title", "value": "s t"},
                ],
            },
        )
        assert serialize(subject.new_title) == expected

    def test_new_title_with_empty_author(self):
        record = self.create_record_with_paired_field(tag="785")
        record["785"]["a"] = ""
        record["880"]["a"] = ""
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="785",
            elements={
                "text": "s t",
                "search": [
                    {"field": "title", "value": "s t"},
                ],
            },
        )

        assert serialize(subject.new_title) == expected

    def test_new_title_with_missing_author(self):
        record = self.create_record_with_paired_field(tag="785", subfields="st")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="785",
            elements={
                "text": "s t",
                "search": [
                    {"field": "title", "value": "s t"},
                ],
            },
        )

        assert serialize(subject.new_title) == expected

    ##################
    # new_title_issn #
    ##################
    def test_new_title_issn(self):
        record = self.create_record_with_paired_field(tag="785")
        subject = MARC(record)
        expected = [{"tag": "785", "text": "x", "browse": None, "search": None}]
        assert serialize(subject.new_title_issn) == expected

    def test_new_title_issn_does_not_have_duplicates(self):
        record = self.create_record_with_paired_field(tag="785")
        subfields = [
            pymarc.Subfield(code=code, value=code)
            for code in list(string.ascii_lowercase)
        ]
        field = pymarc.Field(tag="785", subfields=subfields)
        record.add_field(field)

        subject = MARC(record)
        expected = [{"tag": "785", "text": "x", "browse": None, "search": None}]
        assert serialize(subject.new_title_issn) == expected

    ##################
    # previous_title #
    ##################
    def test_previous_title(self):
        record = self.create_record_with_paired_field(tag="780")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="780",
            elements={
                "text": "a s t",
                "search": [
                    {"field": "author", "value": "a"},
                    {"field": "title", "value": "s t"},
                ],
            },
        )
        assert serialize(subject.previous_title) == expected

    #######################
    # previous_title_issn #
    #######################
    def test_previous_title_issn(self):
        record = self.create_record_with_paired_field(tag="780")
        subject = MARC(record)
        expected = [{"tag": "780", "text": "x", "browse": None, "search": None}]
        assert serialize(subject.previous_title_issn) == expected

    ################
    # contributors #
    ################
    @pytest.mark.parametrize("tag", ["700", "710", "711"])
    def test_contributors_with_indicator_2_not_2_and_no_t(self, tag):
        sfs = string.ascii_lowercase.replace("t", "") + "4"
        record = self.create_record_with_paired_field(tag=tag, subfields=sfs)

        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={
                "text": "a b c d e f g j k l n p q u 4",
                "search": [{"field": "author", "value": "a b c d g j k q u"}],
                "browse": "a b c d g j k q u",
            },
        )

        assert serialize(subject.contributors) == expected

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

    ###########
    # created #
    ###########
    def test_created_264_with_ind_1_as_0(self, a_to_z_str):
        record = self.create_record_with_paired_field(tag="264", ind2="0")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="264",
            elements={
                "text": a_to_z_str,
            },
        )
        assert serialize(subject.created) == expected

    def test_created_not_ind_1_as_0(self):
        record = self.create_record_with_paired_field(tag="264", ind2="1")
        subject = MARC(record)
        assert serialize(subject.created) == []

    ###############
    # distributed #
    ###############
    def test_distributed_264_with_ind_1_as_2(self, a_to_z_str):
        record = self.create_record_with_paired_field(tag="264", ind2="2")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="264",
            elements={
                "text": a_to_z_str,
            },
        )
        assert serialize(subject.distributed) == expected

    def test_distributed_not_ind_1_as_2(self):
        record = self.create_record_with_paired_field(tag="264", ind2="1")
        subject = MARC(record)
        assert serialize(subject.distributed) == []

    ################
    # manufactured #
    ################
    def test_manufactured_260(self):
        record = self.create_record_with_paired_field(tag="260")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="260",
            elements={
                "text": "e f g",
            },
        )

        assert serialize(subject.manufactured) == expected

    def test_manufactured_260_with_missing_fields(self):
        record = self.create_record_with_paired_field(tag="260", subfields="a")
        subject = MARC(record)
        assert subject.manufactured == []

    def test_manufactured_264_with_indicator2_as_3(self, a_to_z_str):
        record = self.create_record_with_paired_field(tag="264", ind2="3")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="264",
            elements={
                "text": a_to_z_str,
            },
        )

        assert serialize(subject.manufactured) == expected

    ##########
    # series #
    ##########

    @pytest.mark.parametrize("tag", ["400", "410", "411", "440", "490"])
    def test_series(self, tag, a_to_z_str):
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": a_to_z_str},
        )
        assert serialize(subject.series) == expected

    def test_series_with_only_880(self, a_to_z_str):
        record = self.create_record_with_paired_field(tag="400")
        record.remove_fields("400")

        subject = MARC(record)
        expected = [
            {
                "original": {
                    "text": a_to_z_str,
                    "tag": "880",
                    "browse": None,
                    "search": None,
                },
                "transliterated": None,
            }
        ]
        assert serialize(subject.series) == expected

    def test_series_with_only_400(self, a_to_z_str):
        record = self.create_record_with_paired_field(tag="400")
        record.remove_fields("880")

        subject = MARC(record)
        expected = [
            {
                "original": {
                    "text": a_to_z_str,
                    "tag": "400",
                    "browse": None,
                    "search": None,
                },
                "transliterated": None,
            }
        ]
        assert serialize(subject.series) == expected

    ####################
    # series statement #
    ####################

    @pytest.mark.parametrize("tag", ["440", "800", "810", "811", "830"])
    def test_series_statement(self, tag, a_to_z_str):
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": a_to_z_str},
        )
        assert serialize(subject.series_statement) == expected

    #####################
    # biography_history #
    #####################

    def test_biography_history(self):
        record = self.create_record_with_paired_field(tag="545")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="545",
            elements={"text": "a"},
        )
        assert serialize(subject.biography_history) == expected

    ###########
    # summary #
    ###########

    def test_summary(self):
        record = self.create_record_with_paired_field(tag="520")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="520",
            elements={"text": "a b c 3"},
        )
        assert serialize(subject.summary) == expected

    def test_summary_ind_1_4(self):
        record = self.create_record_with_paired_field(tag="520", ind1="4")
        subject = MARC(record)
        assert serialize(subject.summary) == []

    #################
    # in collection #
    #################

    def test_in_collection(self, a_to_z_str):
        record = self.create_record_with_paired_field(tag="773")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="773",
            elements={"text": a_to_z_str},
        )
        assert serialize(subject.in_collection) == expected

    ##########
    # access #
    ##########

    def test_access(self):
        record = self.create_record_with_paired_field(tag="506")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="506",
            elements={"text": "a b c"},
        )
        assert serialize(subject.access) == expected

    ################
    # finding_aids #
    ################
    # TODO mrio: I don't think this is right
    def test_finding_aids(self):
        record = self.create_record_with_paired_field(tag="555")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="555",
            elements={"text": "a b c d u 3"},
        )
        assert serialize(subject.finding_aids) == expected

    ################
    # terms_of_use #
    ################
    def test_terms_of_use(self, a_to_z_str):
        record = self.create_record_with_paired_field(tag="540")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="540",
            elements={"text": a_to_z_str},
        )
        assert serialize(subject.terms_of_use) == expected

    #################
    # language_note #
    #################
    def test_language_note(self, a_to_z_str):
        record = self.create_record_with_paired_field(tag="546")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="546",
            elements={"text": a_to_z_str},
        )
        assert serialize(subject.language_note) == expected

    ##############
    # performers #
    ##############
    def test_performers(self):
        record = self.create_record_with_paired_field(tag="511")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="511",
            elements={"text": "a"},
        )
        assert serialize(subject.performers) == expected

    #######################
    # date_place_of_event #
    #######################
    def test_date_place_of_event(self):
        record = self.create_record_with_paired_field(tag="518")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="518",
            elements={"text": "a d o p 2 3"},
        )
        assert serialize(subject.date_place_of_event) == expected

    ######################
    # preferred_citation #
    ######################

    def test_preferred_citation(self):
        tag = "524"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.preferred_citation) == expected

    #########################
    # location_of_originals #
    #########################
    def test_location_of_originals(self, a_to_z_str):
        tag = "535"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": f"{a_to_z_str} 3"},
        )
        assert serialize(subject.location_of_originals) == expected

    #######################
    # funding_information #
    #######################
    def test_funding_information(self):
        tag = "536"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.funding_information) == expected

    ########################
    # source_of_acquistion #
    ########################
    def test_source_of_acquisition(self):
        tag = "541"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.source_of_acquisition) == expected

    #################
    # related_items #
    #################
    def test_related_items(self):
        tag = "580"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.related_items) == expected

    #############
    # numbering #
    #############
    def test_numbering(self):
        tag = "362"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.numbering) == expected

    #################################
    # current_publication_frequency #
    #################################
    def test_current_publication_frequency(self):
        tag = "310"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a b"},
        )
        assert serialize(subject.current_publication_frequency) == expected

    ################################
    # former_publication_frequency #
    ################################
    def test_former_publication_frequency(self):
        tag = "321"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a b"},
        )
        assert serialize(subject.former_publication_frequency) == expected

    ###################
    # numbering_notes #
    ###################
    def test_numbering_notes(self):
        tag = "515"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.numbering_notes) == expected

    ##############################
    # source_of_description_note #
    ##############################
    def test_source_of_description_note(self):
        tag = "588"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.source_of_description_note) == expected

    ######################
    # copy_specific_note #
    ######################
    def test_copy_specific_note(self):
        tag = "590"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.copy_specific_note) == expected

    ##############
    # references #
    ##############
    def test_references(self, a_to_z_str):
        tag = "510"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": a_to_z_str},
        )
        assert serialize(subject.references) == expected

    ################################
    # copyright_status_information #
    ################################
    def test_copyright_status_information(self, a_to_z_str):
        tag = "542"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": a_to_z_str},
        )
        assert serialize(subject.copyright_status_information) == expected

    ########
    # note #
    ########

    @pytest.mark.parametrize(
        "tag",
        [
            "500",
            "501",
            "502",
            "525",
            "526",
            "530",
            "547",
            "550",
            "552",
            "561",
            "565",
            "584",
            "585",
        ],
    )
    def test_note(self, tag):
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.note) == expected

    ###############
    # arrangement #
    ###############
    def test_arrangement(self):
        tag = "351"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a b 3"},
        )
        assert serialize(subject.arrangement) == expected

    #############
    # copyright #
    #############
    def test_copyright_with_ind_2_as_4(self, a_to_z_str):
        tag = "264"
        record = self.create_record_with_paired_field(tag=tag, ind2="4")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": a_to_z_str},
        )
        assert serialize(subject.copyright) == expected

    def test_copyright_with_ind_2_not_4(self):
        tag = "264"
        record = self.create_record_with_paired_field(tag=tag, ind2="1")
        subject = MARC(record)
        assert serialize(subject.copyright) == []

    ########################
    # physical description #
    ########################

    def test_physical_description(self, a_to_z_str):
        record = self.create_record_with_paired_field(tag="300")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag="300",
            elements={"text": a_to_z_str},
        )
        assert serialize(subject.physical_description) == expected

    #############
    # map_scale #
    #############
    def test_map_scale(self):
        tag = "255"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.map_scale) == expected

    #####################
    # reproduction_note #
    #####################
    def test_reproduction_note(self, a_to_z_str):
        tag = "533"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": f"{a_to_z_str} 3 5"},
        )
        assert serialize(subject.reproduction_note) == expected

    #########################
    # original_version_note #
    #########################
    def test_original_version_note(self, a_to_z_str):
        tag = "534"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": f"{a_to_z_str} 3 5"},
        )
        assert serialize(subject.original_version_note) == expected

    ################
    # playing_time #
    ################
    def test_playing_time(self):
        tag = "306"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.playing_time) == expected

    ################
    # media_format #
    ################
    def test_media_format(self):
        tag = "538"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.media_format) == expected

    ############
    # audience #
    ############
    def test_audience(self):
        tag = "521"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.audience) == expected

    ##################
    # content_advice #
    ##################
    def test_content_advice_ind1_as_4(self):
        tag = "520"
        record = self.create_record_with_paired_field(tag=tag, ind1="4")
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a b c 3"},
        )
        assert serialize(subject.content_advice) == expected

    def test_content_advice_ind1_not_4(self):
        tag = "520"
        record = self.create_record_with_paired_field(tag=tag, ind1="1")
        subject = MARC(record)
        assert serialize(subject.content_advice) == []

    ##########
    # awards #
    ##########
    def test_awards(self):
        tag = "586"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.awards) == expected

    ######################
    # production_credits #
    ######################
    def test_production_credits(self):
        tag = "508"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.production_credits) == expected

    ################
    # bibliography #
    ################
    def test_bibliography(self):
        tag = "504"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a"},
        )
        assert serialize(subject.bibliography) == expected

    ####################
    # publisher_number #
    ####################
    def test_publisher_number(self):
        tag = "028"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": "a b"},
        )
        assert serialize(subject.publisher_number) == expected

    ############
    # contents #
    ############
    def test_contents(self, a_to_z_str):
        tag = "505"
        record = self.create_record_with_paired_field(tag=tag)
        subject = MARC(record)
        expected = self.expected_paired_field(
            tag=tag,
            elements={"text": a_to_z_str},
        )
        assert serialize(subject.contents) == expected

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

    def expected_paired_field(self, tag: str, elements: dict):
        result = [
            {
                "transliterated": asdict(FieldElement(tag=tag, **elements)),
                "original": asdict(FieldElement(tag="880", **elements)),
            }
        ]
        return result


def serialize(my_list: list):
    return [asdict(element) for element in my_list]
