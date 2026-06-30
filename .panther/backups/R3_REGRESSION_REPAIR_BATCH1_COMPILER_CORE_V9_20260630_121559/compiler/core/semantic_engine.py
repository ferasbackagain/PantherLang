from compiler.core.diagnostics import DiagnosticBag
from compiler.core.type_checker import TypeChecker

class SemanticEngine:
    def __init__(self):
        self.types = TypeChecker()
        self.diagnostics = DiagnosticBag()

    def analyze_model(self, model):
        names = set()
        for field in model.fields:
            if field.name in names:
                self.diagnostics.error(f"Duplicate field: {field.name}")
            names.add(field.name)
        self.types.check_model(model, {model.name})
        return (not self.diagnostics.has_errors()
                and not self.types.diagnostics.has_errors())
