from pydantic import BaseModel
from typing import Optional


class TextField(BaseModel):
    text: str
    tag: Optional[str] = None


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


class Record(BaseModel):
    id: str
    title: list[PairedTextField]
    format: list[str]
    main_author: list[PairedBrowseField]
    other_titles: list[PairedSearchField]
    contributors: list[PairedBrowseField]
    published: list[PairedTextField]
    manufactured: list[PairedTextField]
    edition: list[PairedTextField]
    series: list[PairedTextField]
