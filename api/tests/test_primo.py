import pytest
import json
from api.primo import Record


@pytest.fixture()
def article_doc():
    bib = {}
    with open("tests/fixtures/article.json") as data:
        bib = json.load(data)
    return bib["docs"][0]


@pytest.fixture()
def subject(article_doc):
    return Record(article_doc)


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
