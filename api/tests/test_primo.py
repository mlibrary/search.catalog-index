import pytest
import json
from api.primo import Record, AlmaHolding, LibKeyHolding, CSL, PrimoDoc, TaggedCitation
from urllib.parse import parse_qs
import re


@pytest.fixture()
def article_doc():
    bib = {}
    with open("tests/fixtures/article.json") as data:
        bib = json.load(data)
    return bib["docs"][0]


@pytest.fixture()
def ht_article_doc():
    bib = {}
    with open("tests/fixtures/ht_article.json") as data:
        bib = json.load(data)
    return bib["docs"][0]


@pytest.fixture()
def naxos_video_article_doc():
    bib = {}
    with open("tests/fixtures/naxos_video_article.json") as data:
        bib = json.load(data)
    return bib["docs"][0]


@pytest.fixture()
def naxos_music_article_doc():
    bib = {}
    with open("tests/fixtures/naxos_music_article.json") as data:
        bib = json.load(data)
    return bib["docs"][0]


@pytest.fixture()
def lib_key_doc():
    result = {}
    with open("tests/fixtures/lib_key.json") as data:
        result = json.load(data)
    return result["data"]


@pytest.fixture()
def subject(article_doc):
    return Record(article_doc)


@pytest.fixture()
def csl_subject(article_doc):

    return CSL(PrimoDoc(article_doc))


class TestRecord:
    def test_id(self, article_doc):
        subject = Record(article_doc)
        assert subject.id == "cdi_projectmuse_ebooks_9781400840458"

    def test_title(self, subject):
        assert subject.title == [
            {"text": "Banding Together: How Communities Create Genres in Popular Music"}
        ]

    # retracted
    # peer_reviewed
    def test_abstract(self, subject):
        assert subject.abstract == [{"text": "This is the abstract"}]

    def test_author(self, article_doc):
        article_doc["pnx"]["addata"]["aucorp"] = ["aucorp"]
        subject = Record(article_doc)
        assert subject.author == [
            {
                "text": "Lena, Jennifer C",
                "search": [{"field": "author", "value": "Lena, Jennifer C"}],
            },
            {
                "text": "aucorp",
                "search": [{"field": "author", "value": "aucorp"}],
            },
        ]

    def test_publisher(self, subject):
        assert subject.publisher == [
            {"text": "Princeton, N.J: Princeton University Press"}
        ]

    def test_genre(self, subject):
        assert subject.genre == [{"text": "book"}]

    def test_issn_is_empty(self, subject):
        assert subject.issn == []

    def test_has_issn(self, article_doc):
        article_doc["pnx"]["addata"]["issn"] = ["first", "second"]
        subject = Record(article_doc)
        assert subject.issn == [{"text": "first"}, {"text": "second"}]

    def test_eissn(self, article_doc):
        article_doc["pnx"]["addata"]["eissn"] = ["first", "second"]
        subject = Record(article_doc)
        assert subject.eissn == [{"text": "first"}, {"text": "second"}]

    def test_isbn(self, subject):
        assert subject.isbn == [
            {"text": "9781400840458"},
            {"text": "1400840457"},
            {"text": "0691163383"},
            {"text": "0691150761"},
            {"text": "9780691150765"},
            {"text": "9780691163383"},
        ]

    def test_eisbn(self, subject):
        assert subject.eisbn == [
            {"text": "9781400840458"},
            {"text": "1400840457"},
        ]

    def test_doi(self, subject):
        assert subject.doi == [{"text": "10.1515/9781400840458"}]

    def test_oclc(self, subject):
        assert subject.oclc == [{"text": "767502420"}]

    def test_pmid(self, article_doc):
        article_doc["pnx"]["addata"]["pmid"] = ["pmid"]
        subject = Record(article_doc)
        assert subject.pmid == [{"text": "pmid"}]

    def test_language(self, subject):
        assert subject.language == [{"text": "English"}]

    def test_subject(self, subject):
        assert subject.subject[0] == {"text": "Afrobeat"}
        assert subject.subject[1] == {"text": "Art music"}

    def test_edition(self, subject):
        assert subject.edition == [{"text": "1"}]


class TestAlmaHolding:
    def test_source(self, article_doc):
        subject = AlmaHolding(article_doc)
        assert subject.source == "alma"

    def test_availability_full_text(self, article_doc):
        subject = AlmaHolding(article_doc)
        assert subject.availability == "full_text"

    def test_availability_citation_only(self, article_doc):
        article_doc["delivery"]["availability"].append("no_fulltext")
        subject = AlmaHolding(article_doc)
        assert subject.availability == "citation_only"

    def test_url_returns_openurl_with_openurl_root(self, article_doc):
        subject = AlmaHolding(article_doc)
        query = parse_qs(subject.url.split("?")[-1])
        assert re.match("https://mgetit", subject.url)
        assert "info:primo/cdi_projectmuse_ebooks_9781400840458" in query["rft_id"]

    def test_takes_url_from_linktosrc(self, ht_article_doc):
        subject = AlmaHolding(ht_article_doc)
        assert re.match("^https://proxy.lib.umich", subject.url)
        assert re.match(".*https://hdl.handle.net/2027/iau.31858029863564", subject.url)

    def test_constructs_naxos_video_link(self, naxos_video_article_doc):
        subject = AlmaHolding(naxos_video_article_doc)
        assert re.match("^https://proxy.lib.umich", subject.url)
        assert re.match(
            ".*https://umich.naxosvideolibrary.com/title/NVF0060",
            subject.url,
        )

    def test_constructs_naxos_music_link(self, naxos_music_article_doc):
        subject = AlmaHolding(naxos_music_article_doc)
        assert re.match("^https://proxy.lib.umich", subject.url)
        assert re.match(
            ".*https://umich.naxosmusiclibrary.com/catalogue/item.asp",
            subject.url,
        )
        assert re.match(
            ".*cid=LBCD11DIG",
            subject.url,
        )

    def test_constructs_gale_link(self, naxos_music_article_doc):
        naxos_music_article_doc["pnx"]["links"]["linktorsrc"][0] = (
            naxos_music_article_doc["pnx"]["links"]["linktorsrc"][0].replace(
                "naxos_music_libray", "gale_linking"
            )
        )

        naxos_music_article_doc["pnx"]["control"]["sourcerecordid"][0] = (
            "source_record_id"
        )
        naxos_music_article_doc["pnx"]["control"]["addsrcrecordid"][0] = (
            "add_src_record_id"
        )

        subject = AlmaHolding(naxos_music_article_doc)
        assert re.match("^https://proxy.lib.umich", subject.url)
        assert re.match(
            ".*https://link.gale.com/apps/doc/source_record_id/add_src_record_id",
            subject.url,
        )
        assert re.match(
            ".*sid=primo&u=umuser",
            subject.url,
        )

    def test_constructs_moazine_link(self, naxos_music_article_doc):
        naxos_music_article_doc["pnx"]["links"]["linktorsrc"][0] = (
            naxos_music_article_doc["pnx"]["links"]["linktorsrc"][0].replace(
                "naxos_music_libray", "moazine_linking"
            )
        )

        naxos_music_article_doc["pnx"]["control"]["sourcerecordid"][0] = (
            "source_record_id"
        )

        subject = AlmaHolding(naxos_music_article_doc)
        assert re.match("^https://proxy.lib.umich", subject.url)
        assert re.match(
            ".*http://dl.moazine.com/viewer3/index.asp.*&article_page=1&articleid=source_record_id",
            subject.url,
        )


class TestLibkeyHolding:
    def test_has_lib_key_source(self, lib_key_doc):
        subject = LibKeyHolding(lib_key_doc)
        assert subject.source == "lib_key"

    def test_has_availability(self, lib_key_doc):
        subject = LibKeyHolding(lib_key_doc)
        assert subject.availability == "full_text"

    def test_availability_is_none_if_fullTextFile_is_empty_string(self, lib_key_doc):
        lib_key_doc["fullTextFile"] = ""
        subject = LibKeyHolding(lib_key_doc)
        assert subject.availability is None

    def test_availability_is_none_if_fullTextFile_is_not_there_at_all(
        self, lib_key_doc
    ):
        del lib_key_doc["fullTextFile"]
        subject = LibKeyHolding(lib_key_doc)
        assert subject.availability is None

    def test_url_is_fullTextFile_value(self, lib_key_doc):
        lib_key_doc["fullTextFile"] = "full_text_file_link"
        subject = LibKeyHolding(lib_key_doc)
        assert subject.url == "full_text_file_link"


class TestCSL:
    def test_has_id(self, csl_subject):
        assert csl_subject.id == "cdi_projectmuse_ebooks_9781400840458"

    def test_has_type(self, csl_subject):
        assert csl_subject.type == "book"

    def test_has_title(self, csl_subject):
        assert (
            csl_subject.title
            == "Banding Together: How Communities Create Genres in Popular Music"
        )

    def test_has_edition(self, csl_subject):
        assert csl_subject.edition == "1"

    def test_has_genre(self, csl_subject):
        assert csl_subject.genre == "book"

    def test_has_isbn(self, csl_subject):
        assert csl_subject.isbn == [
            "9781400840458",
            "1400840457",
            "0691163383",
            "0691150761",
            "9780691150765",
            "9780691163383",
        ]

    def test_has_issn(self, article_doc):
        article_doc["pnx"]["addata"]["issn"] = ["issn"]
        article_doc["pnx"]["addata"]["eissn"] = ["eissn"]
        csl_subject = CSL(PrimoDoc(article_doc))
        assert csl_subject.issn == [
            "issn",
            "eissn",
        ]

    def test_has_publisher(self, csl_subject):
        assert csl_subject.publisher == "Princeton, N.J: Princeton University Press"

    def test_issued(self, csl_subject):
        assert csl_subject.issued == {"literal": "2012"}

    def test_doi(self, csl_subject):
        assert csl_subject.doi == "10.1515/9781400840458"

    def test_author(self, csl_subject):
        assert csl_subject.author == [{"family": "Lena", "given": "Jennifer C"}]

    def test_author_literal(self, article_doc):
        article_doc["pnx"]["addata"]["au"] = ["Lena"]
        csl_subject = CSL(PrimoDoc(article_doc))
        assert csl_subject.author == [{"literal": "Lena"}]

    def test_corporate_author(self, article_doc):
        article_doc["pnx"]["addata"]["aucorp"] = ["Lena, Jennifer C"]
        csl_subject = CSL(PrimoDoc(article_doc))
        assert csl_subject.author == [
            {"family": "Lena", "given": "Jennifer C"},
            {"literal": "Lena, Jennifer C"},
        ]


class TestTaggedCitation:
    def test_handles_fetching_from_control(self, article_doc):
        subject = TaggedCitation(PrimoDoc(article_doc))
        assert subject.to_list(
            [{"section": "control", "field": "recordid", "ris": ["ID"], "meta": ["id"]}]
        )[1] == {
            "content": "cdi_projectmuse_ebooks_9781400840458",
            "ris": ["ID"],
            "meta": ["id"],
        }

    def test_handles_fetching_from_addata_when_not_given_section_and_default_empty_list_for_ris_or_meta(
        self, article_doc
    ):
        subject = TaggedCitation(PrimoDoc(article_doc))
        assert subject.to_list([{"field": "abstract", "ris": ["AB"]}])[1] == {
            "content": "This is the abstract",
            "ris": ["AB"],
            "meta": [],
        }

    def test_handles_multiple_authors(self, article_doc):
        article_doc["pnx"]["addata"]["au"].append("Author, Second")
        subject = TaggedCitation(PrimoDoc(article_doc))
        tagged_list = subject.to_list(
            [{"field": "au", "ris": ["AU"], "meta": ["author"]}]
        )
        assert tagged_list[1] == {
            "content": "Lena, Jennifer C",
            "ris": ["AU"],
            "meta": ["author"],
        }
        assert tagged_list[2] == {
            "content": "Author, Second",
            "ris": ["AU"],
            "meta": ["author"],
        }

    def test_has_type_GEN_when_no_matching_type(self, article_doc):
        article_doc["pnx"]["display"]["type"] = ["whatever"]
        article_doc["pnx"]["facets"]["rsrctype"] = ["whatever"]
        subject = TaggedCitation(PrimoDoc(article_doc))
        assert subject.to_list([])[0] == {
            "content": "GEN",
            "ris": ["TY"],
            "meta": [],
        }

    def test_matches_when_there_is_a_match(self, article_doc):
        subject = TaggedCitation(PrimoDoc(article_doc))
        assert subject.to_list([])[0] == {
            "content": "BOOK",
            "ris": ["TY"],
            "meta": [],
        }
