from pydantic import BaseModel


class TextField(BaseModel):
    text: str


class Linkage(BaseModel):
    tag: str
    occurence_number: str


class SearchField(TextField):
    search: str


class PairedTextField(TextField):
    script: str
    tag: str
    linkage: Linkage | None


class PairedSearchField(PairedTextField):
    search: str


class PairedBrowseField(PairedSearchField):
    browse: str


class PairedNoLinkageTextField(TextField):
    script: str


class PairedNoLinkageSearchField(PairedNoLinkageTextField):
    search: str


class BrowseNoLinkageField(PairedNoLinkageSearchField):
    browse: str


class Record(BaseModel):
    id: str
    title: list[PairedNoLinkageTextField]
    format: list[str]
    main_author: list[BrowseNoLinkageField]
    other_titles: list[PairedSearchField]
    contributors: list[PairedBrowseField]
