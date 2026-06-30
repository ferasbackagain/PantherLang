from language.models.core_models import PantherModel, PantherField
from language.compiler.core.semantic_engine import SemanticEngine

engine = SemanticEngine()

model = PantherModel(
    name="User",
    fields=[
        PantherField("id","uuid"),
        PantherField("name","string"),
        PantherField("email","string")
    ]
)

assert engine.analyze_model(model)
print("✅ Phase 1.4 semantic tests passed.")
