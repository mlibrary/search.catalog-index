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
    manufactured: list[PairedTextField]
    edition: list[PairedTextField]
    series: list[PairedTextField]
    series_statement: list[PairedTextField]
    language: list[BareTextField]
    note: list[PairedTextField]
    physical_description: list[PairedTextField]
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
