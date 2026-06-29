from collections import defaultdict
from uuid import uuid4

class InMemoryDataStore:
    def __init__(self, semantic):
        self.semantic = semantic
        self.records = defaultdict(list)
        self.model_fields = {model.name: model.fields for model in semantic.data_models}

    def list(self, model_name):
        return self.records[model_name]

    def create(self, model_name, payload):
        fields = self.model_fields.get(model_name, [])
        record = {}

        for field in fields:
            if field.name in payload:
                record[field.name] = payload[field.name]
            elif field.name.lower() == "id" and field.type == "UUID":
                record[field.name] = str(uuid4())
            elif field.default is not None:
                record[field.name] = field.default
            elif field.required:
                raise ValueError(f"Missing required field: {field.name}")
            else:
                record[field.name] = None

        self.records[model_name].append(record)
        return record
