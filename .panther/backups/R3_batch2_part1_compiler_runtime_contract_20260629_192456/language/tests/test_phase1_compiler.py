from language.models.core_models import PantherModel, PantherField
from language.compiler.core.compiler import PantherCompiler

m = PantherModel(
    name="User",
    fields=[
        PantherField("id","uuid"),
        PantherField("name","string",required=True),
    ],
)

code = PantherCompiler().compile_models([m],"PantherDemo")
assert "PantherDemo" in code
assert "User" in code
print("✅ Phase 1.7 compiler tests passed.")
