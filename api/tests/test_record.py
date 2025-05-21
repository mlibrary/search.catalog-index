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
        "lcsh_subjects",
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


# def add_none_fields(my_list: list):
#     def none_for(key: str, my_dict: dict):
#         if key not in my_dict:
#             my_dict[key] = None

#     for element in my_list:
#         none_for("browse", element)
#         none_for("search", element)

#     return my_list
