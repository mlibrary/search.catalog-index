import pymarc
from dataclasses import dataclass
import re
import string
from collections.abc import Callable
from catalog_api.entities import SearchField, FieldElement, PairedField


class Linkage:
    def __init__(self, field: pymarc.Field):
        if field.get("6"):
            self.parts = re.split("[-/]", field["6"])
        else:
            self.parts = [None, None]

    @property
    def tag(self):
        return self.parts[0]

    @property
    def occurence_number(self):
        return self.parts[1]

    def __str__(self):
        return f"{self.tag}-{self.occurence_number}"


@dataclass(frozen=True)
class FieldRuleset:
    tags: list
    text_sfs: str = string.ascii_lowercase
    search: list | None = None
    browse_sfs: str | None = None
    filter: Callable[..., bool] = lambda field: True

    def has_any_subfields(self, field: pymarc.Field) -> bool:
        return bool(self._get_subfields(field, self.text_sfs))

    def value_for(self, field: pymarc.Field):
        result = {
            "text": self._get_subfields(field, self.text_sfs).strip(),
            "tag": field.tag,
        }

        if self.search:
            result["search"] = []
            for s in self.search:
                value = self._get_subfields(field, s["subfields"])
                if value:
                    result["search"].append(
                        SearchField(
                            field=s["field"],
                            value=self._get_subfields(field, s["subfields"]),
                        )
                    )

        if self.browse_sfs:
            result["browse"] = self._get_subfields(field, self.browse_sfs)

        return FieldElement(**result)

    def _get_subfields(self, field: pymarc.Field, subfields: str):
        return " ".join(field.get_subfields(*tuple(subfields)))


class Processor:
    def __init__(self, record: pymarc.record.Record):
        self.record = record

    def generate_unpaired_fields(self, rulesets: tuple) -> list:
        result = []
        for ruleset in rulesets:
            for field in self.record.get_fields(*ruleset.tags):
                if ruleset.has_any_subfields(field):
                    result.append(ruleset.value_for(field))

        return list(set(result))

    def generate_paired_fields(self, rulesets: tuple) -> list:
        result = []
        for ruleset in rulesets:
            for fields in self._get_paired_fields_for(ruleset):
                if ruleset.filter(fields["original"]):
                    r = {}
                    for key in fields.keys():
                        r[key] = ruleset.value_for(fields[key])
                    result.append(PairedField(**r))
        return result

    def _get_original_for_tags(self, tags: tuple) -> list:
        def linkage_has_tag(field):
            return Linkage(field).tag in tags

        return list(filter(linkage_has_tag, self.record.get_fields("880")))

    def _get_paired_fields_for(self, ruleset: FieldRuleset) -> list:
        mapping = {}
        for field in self._get_original_for_tags(ruleset.tags):
            mapping[Linkage(field).__str__()] = field

        results = []
        for field in self.record.get_fields(*ruleset.tags):
            if ruleset.has_any_subfields(field):
                original = mapping.pop(
                    f"{field.tag}-{Linkage(field).occurence_number}", None
                )
                if original:
                    results.append({"transliterated": field, "original": original})
                else:
                    results.append({"original": field})

        return results + [
            {"original": f} for f in mapping.values() if ruleset.has_any_subfields(f)
        ]
