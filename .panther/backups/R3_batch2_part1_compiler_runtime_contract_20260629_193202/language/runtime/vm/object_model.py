class PantherObject:
    def __init__(self, type_name, fields=None):
        self.type_name = type_name
        self.fields = fields or {}

    def get(self, name):
        return self.fields.get(name)

    def set(self, name, value):
        self.fields[name] = value

    def to_dict(self):
        return {
            "type": self.type_name,
            "fields": self.fields,
        }


class PantherModelObject(PantherObject):
    pass
