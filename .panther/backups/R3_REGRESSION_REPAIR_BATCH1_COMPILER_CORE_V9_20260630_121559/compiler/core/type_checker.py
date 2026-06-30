from compiler.core.semantic_types import is_builtin_type
from compiler.core.diagnostics import DiagnosticBag

class TypeChecker:
    def __init__(self):
        self.diagnostics = DiagnosticBag()

    def check_field_type(self, type_name: str, known_models=None):
        known_models = known_models or set()
        clean = type_name[:-1] if type_name.endswith("?") else type_name
        if clean in known_models or is_builtin_type(clean):
            return True
        self.diagnostics.error(f"Unknown type: {type_name}")
        return False

    def check_model(self, model, known_models=None):
        known_models = known_models or {model.name}
        for field in model.fields:
            self.check_field_type(field.type_name, known_models)
        return not self.diagnostics.has_errors()
