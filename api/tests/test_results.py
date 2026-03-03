import pytest
from catalog_api.results import Filter


class TestFilter:
    def test_filter_has_values(self):
        subject = Filter(field="format", values=["Value1", 1, "Value2", 25]).values

        assert subject[0].text == "Value1"
        assert subject[0].count == 1
        assert subject[1].text == "Value2"
        assert subject[1].count == 25
