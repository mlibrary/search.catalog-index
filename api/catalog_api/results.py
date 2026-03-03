import json
from pathlib import Path
from dataclasses import dataclass
from catalog_api.record import Record


class Results:
    fixture_path = Path(__file__).parents[0] / "../tests/fixtures/results/"
    with open(fixture_path / "page1.json") as f:
        page1 = json.load(f)

    with open(fixture_path / "page2.json") as f:
        page2 = json.load(f)

    with open(fixture_path / "page3.json") as f:
        page3 = json.load(f)

    def __init__(self, data: dict):
        self.data = self.page1

    @property
    def records(self):
        return [Record(data) for data in self.data["response"]["docs"]]

    @property
    def filters(self):
        facet_fields = self.data["facet_counts"]["facet_fields"]
        return [Filter(field=x, values=facet_fields[x]) for x in facet_fields.keys()]

    @property
    def total(self):
        return self.data["response"]["numFound"]

    @property
    def limit(self):
        return self.data["responseHeader"]["params"]["rows"]

    @property
    def offset(self):
        return self.data["response"]["start"]


# problems with filter data.
# 1. the fields aren't the correct name
# 2. dates probably need to be handled differently
# 3.
class Filter:
    def __init__(self, field: str, values: list):
        self.field = field
        self.values = self.get_values(values)

    def get_values(self, values):
        result = []
        for x in range(0, len(values), 2):
            result.append(FilterValue(text=values[x], count=values[x + 1]))
        return result


@dataclass(frozen=True)
class FilterValue:
    text: str
    count: int
