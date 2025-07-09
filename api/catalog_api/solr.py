from catalog_api.entities import TextField, PairedField


class SolrDocProcessor:
    def __init__(self, data: dict):
        self.data = data

    def get(self, key):
        return self.data.get(key)

    def get_paired_field(self, key):
        values = self.data.get(key) or []
        match len(values):
            case 0:
                return []
            case 1:
                return [PairedField(original=TextField(text=values[0]))]
            case _:
                return [
                    PairedField(
                        transliterated=TextField(text=values[0]),
                        original=TextField(text=values[1]),
                    )
                ]

    def get_text_field(self, key):
        return [TextField(text=value) for value in (self.data.get(key) or [])]

    def get_list(self, key):
        data = self.data.get(key, [])
        if isinstance(data, str):
            return [data]
        return data
