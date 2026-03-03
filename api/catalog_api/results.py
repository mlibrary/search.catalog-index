class Results:
    def __init__(self, data: dict):
        pass

    @property
    def records(self):
        return []

    @property
    def filters(self):
        return []

    @property
    def total(self):
        return 1

    @property
    def limit(self):
        return 2

    @property
    def offset(self):
        return 5
