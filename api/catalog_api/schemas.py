from pydantic import BaseModel, ConfigDict
from typing import Optional


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
    call_number: list[BareTextField]
    oclc: list[BareTextField]
    lcsh_subjects: list[BareTextField]
    academic_discipline: list[AcademicDiscipline]


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
