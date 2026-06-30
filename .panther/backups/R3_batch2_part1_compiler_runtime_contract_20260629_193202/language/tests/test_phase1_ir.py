from language.models.core_models import PantherModel, PantherField
from language.compiler.core.ir_builder import IRBuilder
from language.compiler.core.ir_serializer import ir_to_json


product = PantherModel(
    name="Product",
    fields=[
        PantherField("id", "uuid"),
        PantherField("title", "string", required=True),
        PantherField("price", "decimal", required=True),
    ],
)

builder = IRBuilder()
ir = builder.build_program_from_models([product], name="PantherStore")
data = ir.to_dict()

assert data["kind"] == "IRProgram"
assert data["name"] == "PantherStore"
assert data["models"][0]["name"] == "Product"
assert data["models"][0]["fields"][1]["required"] is True

json_output = ir_to_json(ir)
assert "PantherStore" in json_output
assert "Product" in json_output

print("✅ Phase 1.5 IR tests passed.")
