from language.models.core_models import PantherField, PantherModel
from language.compiler.core.type_checker import TypeChecker
from language.compiler.core.semantic_types import parse_type

product = PantherModel(
    name="Product",
    fields=[
        PantherField("id", "uuid"),
        PantherField("title", "string", required=True),
        PantherField("price", "decimal", required=True),
        PantherField("stock", "int", default=0),
    ],
)

checker = TypeChecker()
assert checker.check_model(product)
assert product.field_names() == ["id", "title", "price", "stock"]

nullable_user = parse_type("User?")
assert nullable_user.name == "User"
assert nullable_user.nullable is True

print("✅ Phase 1 bootstrap tests passed.")
