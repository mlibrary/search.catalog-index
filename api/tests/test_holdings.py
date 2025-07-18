import pytest
import pymarc
import json
import io
from catalog_api.holdings import (
    PhysicalHolding,
    ElectronicItem,
    HathiTrustItem,
    AlmaDigitalItem,
    FindingAidItem,
)


@pytest.fixture
def record():
    bib = {}
    with open("tests/fixtures/land_birds_solr.json") as data:
        bib = json.load(data)
    marc = bib["response"]["docs"][0]["fullrecord"]
    return pymarc.parse_xml_to_array(io.StringIO(marc))[0]


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


@pytest.fixture
def bib_id():
    "9912345"


class TestPhysicalHolding:
    fields = [
        ("holding_id", "hol_mmsid"),
        ("call_number", "callnumber"),
        ("summary", "summary_holdings"),
        ("public_note", "public_note"),
    ]

    @pytest.mark.parametrize("field,solr_field", fields)
    def test_outer_fields(self, field, solr_field, physical_holding, bib_id):
        subject = PhysicalHolding(physical_holding, bib_id=bib_id, record=record)
        assert getattr(subject, field) == physical_holding[solr_field]

    def test_physical_location(self, physical_holding, bib_id):
        subject = PhysicalHolding(
            physical_holding, bib_id=bib_id, record=record
        ).physical_location
        assert subject.url == physical_holding["info_link"]
        assert subject.text == physical_holding["display_name"]
        assert subject.floor == physical_holding["floor_location"]
        assert subject.code.library == physical_holding["library"]
        assert subject.code.location == physical_holding["location"]
        assert subject.temporary is False

    item_fields = [
        ("item_id", "item_id"),
        ("barcode", "barcode"),
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
    def test_items_is_a_list_of_items(
        self, field, solr_field, physical_holding, bib_id, record
    ):
        subject = PhysicalHolding(physical_holding, bib_id=bib_id, record=record).items[
            0
        ]
        expected = physical_holding["items"][0][solr_field]
        assert getattr(subject, field) == expected

    def test_item_has_get_this_url(self, physical_holding, bib_id, record):
        item = physical_holding["items"][0]
        subject = PhysicalHolding(physical_holding, bib_id=bib_id, record=record).items[
            0
        ]
        expected = f"https://search.lib.umich.edu/catalog/record/{bib_id}/get-this/{item['barcode']}"
        assert subject.url == expected

    def test_item_has_request_this_url(self, physical_holding, bib_id, record):
        item = physical_holding["items"][0]
        item["can_reserve"] = True
        expected = f"https://search.lib.umich.edu/catalog/record/{bib_id}/get-this/{item['barcode']}"
        subject = PhysicalHolding(physical_holding, bib_id=bib_id, record=record).items[
            0
        ]
        assert subject.url != expected

    def test_item_has_a_physical_location(
        self, physical_holding, bib_id, record=record
    ):
        subject = (
            PhysicalHolding(physical_holding, bib_id=bib_id, record=record)
            .items[0]
            .physical_location
        )
        expected = physical_holding["items"][0]
        assert subject.url == expected["info_link"]
        assert subject.text == expected["display_name"]
        assert subject.floor is None
        assert subject.code.library == expected["library"]
        assert subject.code.location == expected["location"]
        assert subject.temporary is expected["temp_location"]


@pytest.fixture
def electronic_item():
    return {
        "library": "ELEC",
        "link": "https://na04.alma.exlibrisgroup.com/view/uresolver/01UMICH_INST/openurl-UMAA?u.ignore_date_coverage=true&portfolio_pid=531314984450006381&Force_direct=true",
        "link_text": "Available online",
        "campuses": ["ann_arbor", "flint"],
        "interface_name": "Miscellaneous Ejournals",
        "collection_name": "Miscellaneous Ejournals",
        "authentication_note": [
            "Open access for all users.",
            "Authorized U-M users (+ guests in U-M Libraries).",
        ],
        "description": " Available from 2001.",
        "public_note": "Some public note",
        "note": "Miscellaneous Ejournals. Miscellaneous Ejournals. Open access for all users. Authorized U-M users (+ guests in U-M Libraries)",
        "finding_aid": False,
        "status": "Available",
    }


class TestElectronicItem:
    fields = [
        ("url", "link"),
        ("campuses", "campuses"),
        ("interface_name", "interface_name"),
        ("collection_name", "collection_name"),
        ("description", "description"),
        ("public_note", "public_note"),
        ("note", "note"),
    ]

    @pytest.mark.parametrize("field,solr_field", fields)
    def test_outer_fields(self, field, solr_field, electronic_item):
        subject = ElectronicItem(electronic_item)
        assert getattr(subject, field) == electronic_item[solr_field]

    def test_is_available(self, electronic_item):
        subject = ElectronicItem(electronic_item)
        assert subject.is_available is True

    def test_is_available_when_unavailable(self, electronic_item):
        electronic_item["status"] = "Not Available"
        subject = ElectronicItem(electronic_item)
        assert subject.is_available is False


@pytest.fixture
def finding_aid_item():
    return {
        "link": "http://quod.lib.umich.edu/c/clementsead/umich-wcl-M-341gag?view=text",
        "library": "ELEC",
        "link_text": "Finding aid",
        "description": "Thomas Gage Papers",
        "finding_aid": True,
    }


@pytest.fixture
def finding_aid_physical_holding():
    return {
        "hol_mmsid": "22900647900006381",
        "callnumber": "Manuscripts",
        "library": "CLEM",
        "location": "NONE",
        "info_link": "https://clements.umich.edu/",
        "display_name": "William L. Clements",
        "floor_location": "",
        "public_note": [],
        "items": [
            {
                "barcode": "B4555680",
                "library": "CLEM",
                "location": "NONE",
                "info_link": "https://clements.umich.edu/",
                "display_name": "William L. Clements",
                "fulfillment_unit": "Limited",
                "location_type": "CLOSED",
                "can_reserve": False,
                "permanent_library": "CLEM",
                "permanent_location": "NONE",
                "temp_location": False,
                "callnumber": "Manuscripts M-341",
                "public_note": None,
                "process_type": None,
                "item_policy": None,
                "description": None,
                "inventory_number": None,
                "item_id": "23900647890006381",
                "material_type": "MIXED",
                "record_has_finding_aid": True,
            }
        ],
        "summary_holdings": None,
        "record_has_finding_aid": True,
    }


class TestFindingAidItem:
    def test_url(self, finding_aid_item, finding_aid_physical_holding):
        subject = FindingAidItem(
            finding_aid_item_data=finding_aid_item,
            physical_holding=finding_aid_physical_holding,
        )
        assert subject.url == finding_aid_item["link"]

    def test_decription(self, finding_aid_item, finding_aid_physical_holding):
        subject = FindingAidItem(
            finding_aid_item_data=finding_aid_item,
            physical_holding=finding_aid_physical_holding,
        )
        assert subject.description == finding_aid_item["description"]

    def test_call_number(self, finding_aid_item, finding_aid_physical_holding):
        subject = FindingAidItem(
            finding_aid_item_data=finding_aid_item,
            physical_holding=finding_aid_physical_holding,
        )
        assert subject.call_number == "Manuscripts M-341"

    def test_call_number_handles_missing_item(
        self, finding_aid_item, finding_aid_physical_holding
    ):
        finding_aid_physical_holding["items"] = None
        subject = FindingAidItem(
            finding_aid_item_data=finding_aid_item,
            physical_holding=finding_aid_physical_holding,
        )
        assert subject.call_number is None

    def test_physical_location(self, finding_aid_item, finding_aid_physical_holding):
        subject = FindingAidItem(
            finding_aid_item_data=finding_aid_item,
            physical_holding=finding_aid_physical_holding,
        )
        assert subject.physical_location.text == "William L. Clements"


@pytest.fixture
def ht_item():
    return {
        "id": "mdp.39015040218748",
        "rights": "ic",
        "description": "some_description",
        "collection_code": "MIU",
        "access": False,
        "source": "University of Michigan",
        "status": "Search only (no full text)",
    }


class TestHathiTrustItem:
    fields = ["id", "description", "source", "status"]

    @pytest.mark.parametrize("field", fields)
    def test_outer_fields(self, field, ht_item):
        subject = HathiTrustItem(ht_item)
        assert getattr(subject, field) == ht_item[field]

    def test_url(self, ht_item):
        subject = HathiTrustItem(ht_item)
        assert subject.url == "http://hdl.handle.net/2027/mdp.39015040218748"


@pytest.fixture
def alma_digital_item():
    return {
        "library": "ALMA_DIGITAL",
        "link": "https://umich.alma.exlibrisgroup.com/discovery/delivery/01UMICH_INST:UMICH/121314984090006381",
        "link_text": "Available online",
        "delivery_description": "1 file/s (pdf)",
        "label": "Some Label",
        "public_note": "Access requires institutional login. Authorized U-M users (no guest access).",
    }


class TestAlmaDigitalItem:
    fields = [
        ("url", "link"),
        ("delivery_description", "delivery_description"),
        ("label", "label"),
        ("public_note", "public_note"),
    ]

    @pytest.mark.parametrize("field,solr_field", fields)
    def test_outer_fields(self, field, solr_field, alma_digital_item):
        subject = AlmaDigitalItem(alma_digital_item)
        assert getattr(subject, field) == alma_digital_item[solr_field]
