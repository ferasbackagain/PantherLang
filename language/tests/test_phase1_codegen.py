from language.models.core_models import PantherModel, PantherField
from language.compiler.core.ir_builder import IRBuilder
from language.compiler.core.codegen import PythonCodeGenerator

product = PantherModel(
    name="Product",
    fields=[
        PantherField("id", "uuid"),
        PantherField("title", "string", required=True),
        PantherField("price", "decimal", required=True),
    ],
)

ir = IRBuilder().build_program_from_models([product], name="PantherStore")
code = PythonCodeGenerator().generate(ir)

assert "APP_NAME" in code
assert "PantherStore" in code
assert "Product" in code
assert "MODELS" in code

print("✅ Phase 1.6 code generator tests passed.")
