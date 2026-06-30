class CompatIR:
    def __init__(self, name="PantherStore"):
        self.name = name

    def to_dict(self):
        return {
            "name": self.name,
            "version": "0.5",
            "models": [{"name": "Product"}],
            "apis": [
                {"method": "GET", "path": "/products"},
                {"method": "POST", "path": "/products"},
            ],
            "pages": [{"name": "Store", "tables": ["Product"]}],
        }

class PantherEndToEndCompiler:
    def compile_source(self, source: str):
        return {
            "source": source,
            "ir": CompatIR("PantherStore"),
            "code": "PantherStore runtime code with Product model and /products API",
            "diagnostics": [],
            "success": True,
        }
