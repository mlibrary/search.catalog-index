from pydantic import BaseModel, ConfigDict
from typing import Optional
import datetime


############
# Holdings #
############


class AlmaDigitalItem(BaseModel):
    url: str
    delivery_description: str | None
    label: str | None
    public_note: str | None


class HathiTustItem(BaseModel):
    id: str
    url: str
    description: str | None
    source: str
    status: str


class ElectronicItem(BaseModel):
    url: str | None
    campuses: list[str]
    interface_name: str | None
    collection_name: str | None
    description: str | None
    public_note: str | None
    note: str | None
    is_available: bool


class LibLoc(BaseModel):
    library: str | None
    location: str | None


class PhysicalLocation(BaseModel):
    url: str | None
    text: str | None
    floor: Optional[str] = None
    code: LibLoc
    temporary: bool


class PhysicalItem(BaseModel):
    item_id: str
    barcode: str | None
    fulfillment_unit: str
    call_number: str | None
    process_type: str | None
    item_policy: str | None
    description: str | None
    inventory_number: str | None
    material_type: str | None
    reservable: bool
    physical_location: PhysicalLocation | None


class PhysicalHolding(BaseModel):
    holding_id: str | None
    call_number: str | None
    summary: str | None
    # public_note: str | None
    physical_location: PhysicalLocation
    items: list[PhysicalItem]


class Holdings(BaseModel):
    hathi_trust_items: list[HathiTustItem]
    alma_digital_items: list[AlmaDigitalItem]
    electronic_items: list[ElectronicItem]
    physical: list[PhysicalHolding]


############
# Metadata #
############
class TextField(BaseModel):
    text: str
    tag: Optional[str] = None


class BareTextField(BaseModel):
    text: str


class PairedTextField(BaseModel):
    transliterated: Optional[TextField] = None
    original: TextField


class FieldedSearchField(BaseModel):
    field: str
    value: str


class SearchField(TextField):
    search: list[FieldedSearchField]


class PairedSearchField(BaseModel):
    transliterated: Optional[SearchField] = None
    original: SearchField


class BrowseField(SearchField):
    browse: str
    tag: Optional[str] = None


class PairedBrowseField(BaseModel):
    transliterated: Optional[BrowseField] = None
    original: BrowseField


class AcademicDiscipline(BaseModel):
    list: list[str]


##########
# Record #
##########
class Record(BaseModel):
    id: str
    title: list[PairedTextField]
    format: list[str]
    availability: list[str]
    main_author: list[PairedBrowseField]
    preferred_title: list[PairedSearchField]
    related_title: list[PairedSearchField]
    other_titles: list[PairedSearchField]
    new_title: list[PairedSearchField]
    new_title_issn: list[TextField]
    previous_title: list[PairedSearchField]
    previous_title_issn: list[TextField]
    contributors: list[PairedBrowseField]
    published: list[PairedTextField]
    created: list[PairedTextField]
    distributed: list[PairedTextField]
    manufactured: list[PairedTextField]
    edition: list[PairedTextField]
    series: list[PairedTextField]
    series_statement: list[PairedTextField]
    biography_history: list[PairedTextField]
    summary: list[PairedTextField]
    in_collection: list[PairedTextField]
    access: list[PairedTextField]
    finding_aids: list[PairedTextField]
    terms_of_use: list[PairedTextField]
    language: list[BareTextField]
    language_note: list[PairedTextField]
    performers: list[PairedTextField]
    date_place_of_event: list[PairedTextField]
    preferred_citation: list[PairedTextField]
    location_of_originals: list[PairedTextField]
    funding_information: list[PairedTextField]
    source_of_acquisition: list[PairedTextField]
    related_items: list[PairedTextField]
    numbering: list[PairedTextField]
    current_publication_frequency: list[PairedTextField]
    former_publication_frequency: list[PairedTextField]
    numbering_notes: list[PairedTextField]
    source_of_description_note: list[PairedTextField]
    copy_specific_note: list[PairedTextField]
    references: list[PairedTextField]
    copyright_status_information: list[PairedTextField]
    note: list[PairedTextField]
    arrangement: list[PairedTextField]
    copyright: list[PairedTextField]
    physical_description: list[PairedTextField]
    map_scale: list[PairedTextField]
    reproduction_note: list[PairedTextField]
    original_version_note: list[PairedTextField]
    playing_time: list[PairedTextField]
    media_format: list[PairedTextField]
    audience: list[PairedTextField]
    content_advice: list[PairedTextField]
    awards: list[PairedTextField]
    production_credits: list[PairedTextField]
    bibliography: list[PairedTextField]
    isbn: list[BareTextField]
    issn: list[BareTextField]
    call_number: list[BareTextField]
    oclc: list[BareTextField]
    gov_doc_number: list[BareTextField]
    publisher_number: list[PairedTextField]
    report_number: list[BareTextField]
    lc_subjects: list[BareTextField]
    remediated_lc_subjects: list[BareTextField]
    other_subjects: list[BareTextField]
    academic_discipline: list[AcademicDiscipline]
    contents: list[PairedTextField]
    bookplate: list[BareTextField]
    indexing_date: datetime.date
    holdings: Holdings
    marc: dict


class Response(BaseModel):
    detail: str


class Response404(Response):
    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "detail": "Record not found",
                }
            ]
        }
    )
