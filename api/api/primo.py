from api.clients.exlibris_client import PrimoClient
from api.clients.lib_key_client import LibKeyClient
import yaml
import re
from api.services import S
from urllib.parse import parse_qsl, urlencode
from api.csl import BaseCSL


with open(f"{S.project_root}/config/primo_languages.yaml", "r") as file:
    language_code_to_str = yaml.safe_load(file)

language_str_to_code = {}
for code in language_code_to_str:
    language_str_to_code[language_code_to_str[code]] = code


def record_for(id):
    data = PrimoClient().get_record(id)
    return Record(data)


class PrimoDoc:
    def __init__(self, data):
        self.data = data
        self.pnx = self.data.get("pnx", {})

    @property
    def id(self):
        return self.get_pnx_field_value(section="control", field="recordid")

    @property
    def peer_reviewed(self):
        return (
            self.get_pnx_field_value(section="display", field="lds50")
            == "peer_reviewed"
        )

    @property
    def title(self):
        return self.get_pnx_field_value(section="display", field="title")

    @property
    def journal_title(self):
        return self.get_pnx_field_value("jtitle")

    @property
    def abstract(self):
        return self.get_pnx_field_value(field="abstract")

    @property
    def publisher(self):
        return self.get_pnx_field_value(section="display", field="publisher")

    @property
    def publication_date(self):
        return self.get_pnx_field_value(section="display", field="creationdate")

    @property
    def genre(self):
        return self.get_pnx_field_value("genre")

    @property
    def issn(self):
        return self.get_pnx_field_values("issn")

    @property
    def eissn(self):
        return self.get_pnx_field_values("eissn")

    @property
    def isbn(self):
        return self.get_pnx_field_values("isbn")

    @property
    def eisbn(self):
        return self.get_pnx_field_values("eisbn")

    @property
    def pages(self):
        return self.get_pnx_field_value("pages")

    @property
    def volume(self):
        return self.get_pnx_field_value("volume")

    @property
    def issue(self):
        return self.get_pnx_field_value("issue")

    @property
    def doi(self):
        return self.get_pnx_field_value("doi")

    @property
    def oclc(self):
        return self.get_pnx_field_value("oclcid")

    @property
    def pmid(self):
        return self.get_pnx_field_value("pmid")

    @property
    def subject(self):
        return self.get_pnx_field_values(section="facets", field="topic")

    @property
    def edition(self):
        return self.get_pnx_field_values(section="display", field="edition")

    @property
    def language(self):
        result = []
        for code in self.get_pnx_field_values(section="display", field="language"):
            if code in language_code_to_str:
                result.append(language_code_to_str[code])
        return result

    @property
    def authors(self):
        return self.get_pnx_field_values("au")

    @property
    def corporate_authors(self):
        return self.get_pnx_field_values("aucorp")

    @property
    def formats(self):
        return self.get_pnx_field_values(
            section="display", field="type"
        ) + self.get_pnx_field_values(section="facets", field="rsrctype")

    def get_pnx_field_value(self, field, section="addata"):
        values = self.get_pnx_field_values(section=section, field=field)
        return values[0] if len(values) else None

    def get_pnx_field_values(self, field, section="addata"):
        return self.pnx.get(section, {}).get(field, [])


class Record:
    def __init__(self, data):
        self.data = data
        self.doc = PrimoDoc(data)
        self.pnx = self.data.get("pnx", {})

    @property
    def id(self):
        return self.doc.id

    @property
    def peer_reviewed(self):
        return self.doc.peer_reviewed

    @property
    def title(self):
        return self._plain_text(value=self.doc.title)

    # retracted
    # peer_reviewed

    @property
    def published_in(self):
        values = []
        if self.doc.journal_title:
            values.append(self.doc.journal_title)
        if self.doc.volume:
            values.append(f"Volume {self.doc.volume}")
        if self.doc.issue:
            values.append(f"Issue {self.doc.issue}")
        if self.doc.publication_date:
            values.append(self.doc.publication_date)
        if self.doc.pages:
            values.append(f"pp. {self.doc.pages}")
        value = ", ".join(values)
        return self._plain_text(value=value)

    @property
    def abstract(self):
        return self._plain_text(value=self.doc.abstract)

    @property
    def publisher(self):
        return self._plain_text(value=self.doc.publisher)

    @property
    def genre(self):
        return self._plain_text(value=self.doc.genre)

    @property
    def issn(self):
        return self._multiple_plain_text(values=self.doc.issn)

    @property
    def eissn(self):
        return self._multiple_plain_text(values=self.doc.eissn)

    @property
    def isbn(self):
        return self._multiple_plain_text(values=self.doc.isbn)

    @property
    def eisbn(self):
        return self._multiple_plain_text(values=self.doc.eisbn)

    @property
    def doi(self):
        return self._plain_text(value=self.doc.doi)

    @property
    def oclc(self):
        return self._plain_text(value=self.doc.oclc)

    @property
    def pmid(self):
        return self._plain_text(value=self.doc.pmid)

    @property
    def language(self):
        return [{"text": language} for language in self.doc.language]

    @property
    def subject(self):
        return self._multiple_plain_text(values=self.doc.subject)

    @property
    def author(self):
        return [
            {"text": value, "search": [{"field": "author", "value": value}]}
            for value in self.doc.authors + self.doc.corporate_authors
        ]

    @property
    def edition(self):
        return self._multiple_plain_text(values=self.doc.edition)

    @property
    def citation(self):
        return Citation(self.doc)

    def _multiple_plain_text(self, section="addata", field=None, values=None):
        if values is None:
            values = self.doc.get_pnx_field_values(section=section, field=field)
        return [{"text": value} for value in values]

    def _plain_text(self, section="addata", field=None, value=None):
        if value is None:
            value = self.doc.get_pnx_field_value(section=section, field=field)
        return [{"text": value}] if value else []

    @property
    def holdings(self):
        lib_key = get_lib_key_holding(
            doi=self.doc.doi,
            pmid=self.doc.pmid,
        )
        result = []
        if lib_key and lib_key.availability:
            result.append(lib_key)
        result.append(AlmaHolding(self.data))
        return result


def get_lib_key_holding(doi, pmid):
    if not doi and not pmid:
        return None

    data = None
    if pmid:
        data = LibKeyClient().get_article(kind="pmid", value=pmid)
    if doi and not data:
        data = LibKeyClient().get_article(kind="doi", value=doi)

    if data:
        return LibKeyHolding(data)


class AlmaHolding:
    source = "alma"

    def __init__(self, data):
        self.data = data

    @property
    def availability(self):
        if "no_fulltext" in self._raw_availability():
            return "citation_only"
        return "full_text"

        return "full_text"

    @property
    def url(self):
        if any("linktorsrc" in status for status in self._raw_availability()):
            return self.link_to_resource() or self.constructed_link_to_resource()
        return self.open_url()

    def open_url(self):
        alma_open_url = self.data.get("delivery", {}).get("almaOpenurl", "")
        query = parse_qsl(alma_open_url.split("?", 1)[-1])
        query.append(
            ["rft_id", f"info:primo/{self.data['pnx']['control']['recordid'][0]}"]
        )

        return f"{S.open_url_root}?{urlencode(query)}"

    def link_to_resource(self):

        destination = self._linktorsrc_value("U")
        if destination:
            return f"{S.proxy_prefix}{destination}"

    def constructed_link_to_resource(self):

        link_type = self._linktorsrc_value("T")

        match link_type:
            case "naxos_video":
                return f"{S.proxy_prefix}https://umich.naxosvideolibrary.com/title/{self._source_record_id()}"
            case "naxos_music_library" | "naxos_music_libray":
                return f"{S.proxy_prefix}https://umich.naxosmusiclibrary.com/catalogue/item.asp?cid={self._source_record_id()}"
            case "gale_linking":
                return f"{S.proxy_prefix}https://link.gale.com/apps/doc/{self._source_record_id()}/{self._additional_source_record_id()}&sid=primo&u=umuser"
            case "moazine_linking":
                return f"{S.proxy_prefix}http://dl.moazine.com/viewer3/index.asp?libraryid=9MtJb2T3nzH3BEvu609VaY52Ca3EA1Y2EWW0&article_page=1&articleid={self._source_record_id()}"

    def _linktorsrc_value(self, subfield_code):
        linktorsrc = self.data.get("pnx", {}).get("links", {}).get("linktorsrc", [])[0]

        def has_subfield(string):
            return string != "" and string[0] == subfield_code

        templates = list(filter(has_subfield, linktorsrc.split("$$")))
        if templates:
            return templates[0][1:]

    def _raw_availability(self):
        return self.data.get("delivery", {}).get("availability", [])

    def _source_record_id(self):
        return self.data.get("pnx", {}).get("control", {}).get("sourcerecordid", [])[0]

    def _additional_source_record_id(self):
        return self.data.get("pnx", {}).get("control", {}).get("addsrcrecordid", [])[0]


class LibKeyHolding:
    source = "lib_key"

    def __init__(self, data):
        self.data = data

    @property
    def availability(self):
        if self.data.get("fullTextFile"):
            return "full_text"

    @property
    def url(self):
        return self.data.get("fullTextFile")


class CSL(BaseCSL):
    TYPE_MAPPING = {
        "archival_material_manuscript": "manuscript",
        "archival_material_manuscripts": "manuscript",
        "article": "article-journal",
        "articles": "article-journal",
        "audio": "article",
        "audios": "article",
        "book": "book",
        "book_chapter": "chapter",
        "book_chapters": "chapter",
        "books": "book",
        "conference_proceeding": "paper-conference",
        "conference_proceedings": "paper-conference",
        "dataset": "dataset",
        "datasets": "dataset",
        "dissertation": "thesis",
        "dissertations": "thesis",
        "government_document": "article",
        "government_documents": "article",
        "image": "graphic",
        "images": "graphic",
        "journal": "article-journal",
        "journals": "article-journal",
        "magazinearticle": "article-magazine",
        "magazinearticles": "article-magazine",
        "newsletterarticle": "article",
        "newsletterarticles": "article",
        "newspaper_article": "article-newspaper",
        "newspaper_articles": "article-newspaper",
        "patent": "patent",
        "patents": "patent",
        "reference_entry": "article-journal",
        "reference_entrys": "article-journal",
        "report": "report",
        "reports": "report",
        "review": "review",
        "reviews": "review",
        "standard": "article",
        "standards": "article",
        "text_resource": "article",
        "text_resources": "article",
        "video": "motion_picture ",
        "videos": "motion_picture",
        "web_resource": "webpage",
        "web_resources": "webpage",
    }

    def __init__(self, doc):
        self.doc = doc

    @property
    def id(self):
        return self.doc.id

    @property
    def title(self):
        return self.doc.title

    @property
    def author(self):
        result = []
        for au in self.doc.authors:
            if re.search(", ", au):
                family, given = au.split(", ")
                result.append({"family": family, "given": given})
            else:
                result.append({"literal": au})
        for au in self.doc.corporate_authors:
            result.append({"literal": au})

        return result

    @property
    def issued(self):
        date_str = self.doc.get_pnx_field_value(section="display", field="creationdate")
        if date_str:
            return {"literal": date_str}

    @property
    def page(self):
        return self.doc.pages

    @property
    def publisher(self):
        return self.doc.publisher

    @property
    def container_title(self):
        return self.doc.journal_title

    @property
    def volume(self):
        return self.doc.volume

    @property
    def issue(self):
        return self.doc.issue

    @property
    def genre(self):
        return self.doc.genre

    @property
    def isbn(self):
        result = self.doc.isbn + self.doc.eisbn
        return list(dict.fromkeys(result))

    @property
    def issn(self):
        result = self.doc.issn + self.doc.eissn
        return list(dict.fromkeys(result))

    @property
    def doi(self):
        return self.doc.doi

    @property
    def edition(self):
        if len(self.doc.edition):
            return self.doc.edition[0]

    def _formats(self):
        return self.doc.formats


class TaggedCitation:
    # The meta tags come from: https://www.zotero.org/support/dev/exposing_metadata
    TAG_MAPPING = [
        {"field": "id", "ris": ["ID"], "meta": ["id"]},
        {"field": "title", "ris": ["T1", "TI"], "meta": ["title"]},
        {"field": "authors", "ris": ["AU"], "meta": ["author"]},
        {"field": "corporate_authors", "ris": ["AU"], "meta": ["author"]},
        {"field": "publisher", "ris": ["PB"], "meta": ["publisher"]},
        {"field": "journal_title", "ris": ["JF", "JO"], "meta": ["journal_title"]},
        {"field": "pages", "ris": ["SP"], "meta": ["pages"]},
        {"field": "volume", "ris": ["VL"], "meta": ["volume"]},
        {"field": "issue", "ris": ["IS"], "meta": ["issue"]},
        {"field": "isbn", "ris": ["SN"], "meta": ["isbn"]},
        {"field": "eisbn", "ris": ["SN"], "meta": ["isbn"]},
        {"field": "issn", "ris": ["SN"], "meta": ["issn"]},
        {"field": "eissn", "ris": ["SN"], "meta": ["eIssn"]},
        {"field": "doi", "ris": ["DO"], "meta": ["doi"]},
        {"field": "language", "ris": ["LA"], "meta": ["language"]},
        {"field": "subject", "ris": ["KW"], "meta": ["keywords"]},
        {"field": "abstract", "ris": ["AB", "N2"], "meta": ["abstract"]},
    ]

    TYPE_MAPPING = {
        "archival_material_manuscript": "MANSCPT",
        "archival_material_manuscripts": "MANSPCT",
        "article": "JOUR",
        "articles": "JOUR",
        "audio": "SOUND",
        "audios": "SOUND",
        "book": "BOOK",
        "book_chapter": "CHAP",
        "book_chapters": "CHAP",
        "books": "BOOK",
        "conference_proceeding": "CONF",
        "conference_proceedings": "CONF",
        "dataset": "DBASE",
        "datasets": "DBASE",
        "dissertation": "THES",
        "dissertations": "THES",
        "government_document": "GOVDOC",
        "government_documents": "GOVDOC",
        "image": "ADVS",
        "images": "ADVS",
        "journal": "JOUR",
        "journals": "JOUR",
        "magazinearticle": "MGZN",
        "magazinearticles": "MGZN",
        "newsletterarticle": "NEWS",
        "newsletterarticles": "NEWS",
        "newspaper_article": "NEWS",
        "newspaper_articles": "NEWS",
        "patent": "PAT",
        "patents": "PAT",
        "reference_entry": "JOUR",
        "reference_entrys": "JOUR",
        "report": "RPRT",
        "reports": "RPRT",
        "review": "JOUR",
        "reviews": "JOUR",
        "standard": "JOUR",
        "standards": "JOUR",
        "text_resource": "JOUR",
        "text_resources": "JOUR",
        "video": "VIDEO",
        "videos": "VIDEO",
        "web_resource": "WEB",
        "web_resources": "WEB",
    }

    def __init__(self, doc):
        self.doc = doc

    def to_list(self, tag_mapping=TAG_MAPPING):
        result = [self._type()]
        for element in tag_mapping:
            if hasattr(self.doc, element["field"]):
                contents = getattr(self.doc, element["field"])
                if contents is None:
                    continue
                elif type(contents) is str:
                    contents = [contents]
            else:
                contents = self.doc.get_pnx_field_values(
                    section=element.get("section", "addata"),
                    field=element.get("field"),
                )
            for content in contents:
                result.append(
                    {
                        "content": content,
                        "ris": element.get("ris", []),
                        "meta": element.get("meta", []),
                    }
                )
        result += self._end_record_tag()
        return result

    def _type(self):
        content = "GEN"
        for f in self.doc.formats:
            c = self.TYPE_MAPPING.get(f)
            if c:
                content = c
                break

        return {
            "content": content,
            "ris": ["TY"],
            "meta": [],
        }

    def _end_record_tag(self):
        return [
            {
                "content": "",
                "ris": ["ER"],
                "meta": [],
            },
        ]


class Citation:
    def __init__(self, doc):
        self.doc = doc

    @property
    def tagged(self):
        return TaggedCitation(self.doc).to_list()

    @property
    def csl(self):
        return CSL(self.doc)
