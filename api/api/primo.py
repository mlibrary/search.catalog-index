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

    def get_pnx_field_value(self, section, field):
        values = self.get_pnx_field_values(section, field)
        return values[0] if len(values) else None

    def get_pnx_field_values(self, section, field):
        return self.pnx.get(section, {}).get(field, [])


class Record:
    def __init__(self, data):
        self.data = data
        self.doc = PrimoDoc(data)
        self.pnx = self.data.get("pnx", {})

    @property
    def id(self):
        return self.doc.get_pnx_field_value(section="control", field="recordid")

    @property
    def title(self):
        return self._plain_text(section="display", field="title")

    # retracted
    # peer_reviewed

    @property
    def abstract(self):
        return self._plain_text(section="addata", field="abstract")

    @property
    def publisher(self):
        return self._plain_text(section="display", field="publisher")

    @property
    def genre(self):
        return self._plain_text(section="addata", field="genre")

    @property
    def issn(self):
        return self._multiple_plain_text(section="addata", field="issn")

    @property
    def eissn(self):
        return self._multiple_plain_text(section="addata", field="eissn")

    @property
    def isbn(self):
        return self._multiple_plain_text(section="addata", field="isbn")

    @property
    def eisbn(self):
        return self._multiple_plain_text(section="addata", field="eisbn")

    @property
    def doi(self):
        return self._plain_text(section="addata", field="doi")

    @property
    def oclc(self):
        return self._plain_text(section="addata", field="oclcid")

    @property
    def pmid(self):
        return self._plain_text(section="addata", field="pmid")

    @property
    def language(self):
        result = []
        for code in self.doc.get_pnx_field_values("display", "language"):
            if code in language_code_to_str:
                result.append({"text": language_code_to_str[code]})
        return result

    @property
    def subject(self):
        return self._multiple_plain_text(section="facets", field="topic")

    @property
    def author(self):
        result = []
        for value in self.doc.get_pnx_field_values("addata", "au"):
            result.append(
                {"text": value, "search": [{"field": "author", "value": value}]}
            )
        for value in self.doc.get_pnx_field_values("addata", "aucorp"):
            result.append(
                {"text": value, "search": [{"field": "author", "value": value}]}
            )
        return result

    @property
    def edition(self):
        return self._multiple_plain_text(section="display", field="edition")

    def _multiple_plain_text(self, section, field):
        values = self.doc.get_pnx_field_values(section, field)
        return [{"text": value} for value in values]

    def _plain_text(self, section, field):
        value = self.doc.get_pnx_field_value(section, field)
        return [{"text": value}] if value else []

    @property
    def holdings(self):
        lib_key = get_lib_key_holding(
            doi=self.doc.get_pnx_field_value("addata", "doi"),
            pmid=self.doc.get_pnx_field_value("addata", "pmid"),
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

    def __init__(self, data):
        self.data = data
        self.doc = PrimoDoc(data)

    @property
    def id(self):
        return self.doc.get_pnx_field_value("control", "recordid")

    @property
    def title(self):
        return self.doc.get_pnx_field_value("display", "title")

    @property
    def author(self):
        result = []
        for au in self.doc.get_pnx_field_values("addata", "au"):
            if re.search(", ", au):
                family, given = au.split(", ")
                result.append({"family": family, "given": given})
            else:
                result.append({"literal": au})
        for au in self.doc.get_pnx_field_values("addata", "aucorp"):
            result.append({"literal": au})

        return result

    @property
    def issued(self):
        date_str = self.doc.get_pnx_field_value("display", "creationdate")
        if date_str:
            return {"literal": date_str}

    @property
    def page(self):
        return self.doc.get_pnx_field_value("addata", "pages")

    @property
    def publisher(self):
        return self.doc.get_pnx_field_value("display", "publisher")

    @property
    def container_title(self):
        return self.doc.get_pnx_field_value("addata", "jtitle")

    @property
    def volume(self):
        return self.doc.get_pnx_field_value("addata", "volume")

    @property
    def issue(self):
        return self.doc.get_pnx_field_value("addata", "issue")

    @property
    def genre(self):
        return self.doc.get_pnx_field_value("addata", "genre")

    @property
    def isbn(self):
        result = self.doc.get_pnx_field_values(
            "addata", "isbn"
        ) + self.doc.get_pnx_field_values("addata", "eisbn")
        return list(dict.fromkeys(result))

    @property
    def issn(self):
        result = self.doc.get_pnx_field_values(
            "addata", "issn"
        ) + self.doc.get_pnx_field_values("addata", "eissn")
        return list(dict.fromkeys(result))

    @property
    def doi(self):
        return self.doc.get_pnx_field_value("addata", "doi")

    @property
    def edition(self):
        return self.doc.get_pnx_field_value("display", "edition")

    def _formats(self):
        return self.doc.get_pnx_field_values(
            "display", "type"
        ) + self.doc.get_pnx_field_values("facets", "rsrctype")


class TaggedCitation:
    def __init__(self, data):
        self.data = data

    def to_list(self):
        pass


class Citation:
    def __init__(self):
        pass

    @property
    def tagged(self):
        return TaggedCitation().to_list()

    @property
    def csl(self):
        return CSL()
