import pytest
from catalog_api.holdings import PhysicalHolding


@pytest.fixture
def physical_holdings():
    return [
        {
            "hol_mmsid": "22857812530006381",
            "callnumber": "QL 691 .J3 S25 1983",
            "library": "MUSM",
            "location": "BIR",
            "info_link": "http://lib.umich.edu/locations-and-hours/museums-library",
            "display_name": "Research Museums Center Birds Division",
            "floor_location": "some_floor_location",
            "public_note": None,
            "items": [
                {
                    "barcode": "39015052384248",
                    "library": "SOME_LIBRARY",
                    "location": "SOME_LOCATION",
                    "info_link": "http://lib.umich.edu/locations-and-hours/museums-library",
                    "display_name": "Some display name",
                    "fulfillment_unit": "General",
                    "location_type": "OPEN",
                    "can_reserve": False,
                    "permanent_library": "MUSM",
                    "permanent_location": "BIR",
                    "temp_location": True,
                    "callnumber": "QL 691 .J3 S25 1983",
                    "public_note": "some_public_note",
                    "process_type": "some_process_type",
                    "item_policy": "01",
                    "description": "description",
                    "inventory_number": "inventory_number",
                    "item_id": "23857812520006381",
                    "material_type": "BOOK",
                    "record_has_finding_aid": False,
                }
            ],
            "summary_holdings": None,
            "record_has_finding_aid": False,
        }
    ]


@pytest.fixture
def physical_holding(physical_holdings):
    return physical_holdings[0]


class TestPhysicalHolding:
    fields = [
        ("holding_id", "hol_mmsid"),
        ("call_number", "callnumber"),
        ("summary", "summary_holdings"),
        ("public_note", "public_note"),
    ]

    @pytest.mark.parametrize("field,solr_field", fields)
    def test_outer_fields(self, field, solr_field, physical_holding):
        subject = PhysicalHolding(physical_holding)
        assert getattr(subject, field) == physical_holding[solr_field]

    def test_physical_location(self, physical_holding):
        subject = PhysicalHolding(physical_holding).physical_location
        assert subject.url == physical_holding["info_link"]
        assert subject.text == physical_holding["display_name"]
        assert subject.floor == physical_holding["floor_location"]
        assert subject.code.library == physical_holding["library"]
        assert subject.code.location == physical_holding["location"]
        assert subject.temporary is False

    item_fields = [
        ("item_id", "item_id"),
        ("fulfillment_unit", "fulfillment_unit"),
        ("call_number", "callnumber"),
        ("process_type", "process_type"),
        ("item_policy", "item_policy"),
        ("description", "description"),
        ("inventory_number", "inventory_number"),
        ("material_type", "material_type"),
        ("reservable", "can_reserve"),
    ]

    @pytest.mark.parametrize("field,solr_field", item_fields)
    def test_items_is_a_list_of_items(self, field, solr_field, physical_holding):
        subject = PhysicalHolding(physical_holding).items[0]
        expected = physical_holding["items"][0][solr_field]
        assert getattr(subject, field) == expected

    def test_item_has_a_physical_location(self, physical_holding):
        subject = PhysicalHolding(physical_holding).items[0].physical_location
        expected = physical_holding["items"][0]
        assert subject.url == expected["info_link"]
        assert subject.text == expected["display_name"]
        assert subject.floor is None
        assert subject.code.library == expected["library"]
        assert subject.code.location == expected["location"]
        assert subject.temporary is expected["temp_location"]
