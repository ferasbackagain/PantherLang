from language.compiler.ast.ast_builder import RealASTBuilder
from language.compiler.integration import PantherEndToEndCompiler

source = open("language/examples/phase2_full_system.panther").read()

ast = RealASTBuilder().build(source)

assert ast.app.name == "PantherStore"
assert ast.app.version == "0.5"
assert len(ast.models) == 2
assert ast.models[0].name == "Product"
assert ast.models[0].fields[1].name == "title"
assert ast.models[0].fields[1].required is True
assert ast.apis[0].method == "GET"
assert ast.apis[0].path == "/products"
assert ast.pages[0].name == "Products"
assert ast.pages[0].table == "Product"
assert ast.agents[0].name == "InventoryAI"
assert ast.agents[0].memory == "scoped"

compiled = PantherEndToEndCompiler().compile_source(source)

assert compiled["ir"].to_dict()["name"] == "PantherStore"
assert "PantherStore" in compiled["code"]
assert "Product" in compiled["code"]
assert "User" in compiled["code"]

print("✅ Phase 2.2–2.10 full compiler pipeline tests passed.")
