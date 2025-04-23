from pydantic import BaseModel


class TextField(BaseModel):
    text: str


class PairedTextField(TextField):
    script: str


class Record(BaseModel):
    id: str
    title: list[PairedTextField]
    format: list[str]
