from pydantic import BaseModel


class TextField(BaseModel):
    text: str


class SearchField(TextField):
    search: str


class PairedTextField(TextField):
    script: str


class PairedSearchField(PairedTextField):
    search: str


class BrowseField(PairedSearchField):
    browse: str


class Record(BaseModel):
    id: str
    title: list[PairedTextField]
    format: list[str]
    main_author: list[BrowseField]
    other_titles: list[SearchField]
