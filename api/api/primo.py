from api.exlibris_client import PrimoClient
import yaml
from api.services import S


with open(f"{S.project_root}/config/primo_languages.yaml", "r") as file:
    language_code_to_str = yaml.safe_load(file)

language_str_to_code = {}
for code in language_code_to_str:
    language_str_to_code[language_code_to_str[code]] = code


def record_for(id):
    data = PrimoClient().get_record(id)
    return Record(data)


class Record:
    def __init__(self, data):
        self.data = data
        self.pnx = self.data.get("pnx", {})

    @property
    def id(self):
        return self._get_field_value(section="control", field="recordid")

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
        for code in self._get_field_values("display", "language"):
            if code in language_code_to_str:
                result.append({"text": language_code_to_str[code]})
        return result

    @property
    def subject(self):
        return self._multiple_plain_text(section="facets", field="topic")

    @property
    def author(self):
        result = []
        for value in self._get_field_values("addata", "au"):
            result.append(
                {"text": value, "search": [{"field": "author", "value": value}]}
            )
        for value in self._get_field_values("addata", "aucorp"):
            result.append(
                {"text": value, "search": [{"field": "author", "value": value}]}
            )
        return result

    @property
    def edition(self):
        return self._multiple_plain_text(section="display", field="edition")

    def _multiple_plain_text(self, section, field):
        values = self._get_field_values(section, field)
        return [{"text": value} for value in values]

    def _plain_text(self, section, field):
        value = self._get_field_value(section, field)
        return [{"text": value}] if value else []

    def _get_field_value(self, section, field):
        values = self._get_field_values(section, field)
        return values[0] if len(values) else None

    def _get_field_values(self, section, field):
        return self.pnx.get(section, {}).get(field, [])
