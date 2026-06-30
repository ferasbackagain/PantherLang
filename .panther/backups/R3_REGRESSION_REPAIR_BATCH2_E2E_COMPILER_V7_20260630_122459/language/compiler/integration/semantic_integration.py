from language.compiler.core.semantic_engine import SemanticEngine
from language.models.core_models import PantherModel, PantherField


class Phase2SemanticIntegration:
    def ast_model_to_core_model(self, ast_model):
        return PantherModel(
            name=ast_model.name,
            fields=[
                PantherField(
                    name=f.name,
                    type_name=f.type_name,
                    required=f.required,
                    default=f.default or None,
                )
                for f in ast_model.fields
            ],
        )

    def analyze(self, ast_program):
        engine = SemanticEngine()
        ok = True
        core_models = []
        for ast_model in ast_program.models:
            core_model = self.ast_model_to_core_model(ast_model)
            core_models.append(core_model)
            if not engine.analyze_model(core_model):
                ok = False
        return ok, core_models
