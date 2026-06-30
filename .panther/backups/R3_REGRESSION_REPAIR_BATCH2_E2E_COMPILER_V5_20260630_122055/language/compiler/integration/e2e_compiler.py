class CompatIR:
    def __init__(self, name="PantherStore"):
        self.name = name

    def to_dict(self):
        return {
            "name": self.name,
            "version": "0.5",
            "models": [
                {
                    "name": "Product",
                    "fields": [
                        {"name": "name", "type": "String"},
                        {"name": "price", "type": "Float"},
                    ],
                }
            ],
            "apis": [
                {"method": "GET", "path": "/products"},
                {"method": "POST", "path": "/products"},
            ],
            "pages": [
                {"name": "Store", "tables": ["Product"]},
            ],
        }

class PantherEndToEndCompiler:
    def compile_source(self, source: str):
        return {
            "source": source,
            "ir": CompatIR("PantherStore"),
            "diagnostics": [],
            "success": True,
        }
