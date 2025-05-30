from dataclasses import dataclass


class HathiTrustItem:
    def __init__(self, ht_item_data: dict):
        self.data = ht_item_data

    @property
    def id(self):
        return self.data.get("id")

    @property
    def url(self):
        return f"http://hdl.handle.net/2027/{self.id}"

    @property
    def description(self):
        return self.data.get("description")

    @property
    def source(self):
        return self.data.get("source")

    @property
    def status(self):
        return self.data.get("status")


class ElectronicItem:
    def __init__(self, electronic_item_data: dict):
        self.data = electronic_item_data

    @property
    def url(self):
        return self.data.get("link")

    @property
    def campuses(self):
        return self.data.get("campuses")

    @property
    def interface_name(self):
        return self.data.get("interface_name")

    @property
    def collection_name(self):
        return self.data.get("collection_name")

    @property
    def description(self):
        return self.data.get("description")

    @property
    def public_note(self):
        return self.data.get("public_note")

    @property
    def note(self):
        return self.data.get("note")

    @property
    def is_available(self):
        return self.data.get("status") == "Available"


@dataclass(frozen=True)
class LibLoc:
    library: str
    location: str


@dataclass(frozen=True)
class PhysicalLocation:
    url: str
    text: str = None
    floor: str = None
    code: LibLoc = None
    temporary: bool = False


class PhysicalItem:
    def __init__(self, physical_item_data: dict):
        self.data = physical_item_data

    @property
    def item_id(self):
        return self.data.get("item_id")

    @property
    def fulfillment_unit(self):
        return self.data.get("fulfillment_unit")

    @property
    def call_number(self):
        return self.data.get("callnumber")

    @property
    def process_type(self):
        return self.data.get("process_type")

    @property
    def item_policy(self):
        return self.data.get("item_policy")

    @property
    def description(self):
        return self.data.get("description")

    @property
    def inventory_number(self):
        return self.data.get("inventory_number")

    @property
    def material_type(self):
        return self.data.get("material_type")

    @property
    def reservable(self):
        return self.data.get("can_reserve")

    @property
    def physical_location(self):
        return PhysicalLocation(
            url=self.data.get("info_link"),
            text=self.data.get("display_name"),
            code=LibLoc(
                library=self.data.get("library"), location=self.data.get("location")
            ),
            temporary=self.data.get("temp_location"),
        )


class PhysicalHolding:
    def __init__(self, physical_holding_data: list):
        self.data = physical_holding_data

    @property
    def holding_id(self):
        return self.data.get("hol_mmsid")

    @property
    def call_number(self):
        return self.data.get("callnumber")

    @property
    def summary(self):
        return self.data.get("summary_holdings")

    @property
    def public_note(self):
        return self.data.get("public_note")

    @property
    def physical_location(self):
        return PhysicalLocation(
            url=self.data.get("info_link"),
            text=self.data.get("display_name"),
            floor=self.data.get("floor_location"),
            code=LibLoc(
                library=self.data.get("library"), location=self.data.get("location")
            ),
        )

    @property
    def items(self):
        return [PhysicalItem(item) for item in self.data.get("items", [])]


def kind_of_holding(holding_item: dict):
    match holding_item["library"]:
        case "ALMA_DIGITAL":
            return None
        case "HathiTrust Digital Library":
            return "hathi_trust"
        case "ELEC":
            return "electronic"
        case _:
            return "physical"


def physical_holdings(holdings_data: list) -> list[PhysicalHolding]:
    return [
        PhysicalHolding(holding_item)
        for holding_item in holdings_data
        if kind_of_holding(holding_item) == "physical"
    ]


def electronic_items(holdings_data: list) -> list[ElectronicItem]:
    return [
        ElectronicItem(holding_item)
        for holding_item in holdings_data
        if kind_of_holding(holding_item) == "electronic"
    ]


def hathi_trust_items(holdings_data: list) -> list[HathiTrustItem]:
    ht_holding = None
    for holding_item in holdings_data:
        if kind_of_holding(holding_item) == "hathi_trust":
            ht_holding = holding_item

    if ht_holding:
        return [HathiTrustItem(item) for item in ht_holding["items"]]
    else:
        return []


class Holdings:
    def __init__(self, holdings_data: list):
        self.data = holdings_data

    @property
    def physical(self):
        return physical_holdings(self.data)

    @property
    def electronic_items(self):
        return electronic_items(self.data)

    @property
    def hathi_trust_items(self):
        return hathi_trust_items(self.data)
