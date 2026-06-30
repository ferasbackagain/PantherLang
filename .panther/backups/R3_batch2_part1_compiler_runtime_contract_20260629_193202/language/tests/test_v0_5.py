from pathlib import Path
from compiler.core.tokenizer import tokenize
from compiler.core.parser import parse_tokens
from compiler.core.semantic import build_semantic_model
from compiler.core.ir import semantic_to_ir

source = Path("examples/store.panther").read_text()
program = parse_tokens(tokenize(source))
semantic = build_semantic_model(program)
ir = semantic_to_ir(semantic)

assert semantic.app_name == "PantherStore"
assert semantic.data_models[0].name == "Product"
assert semantic.apis[0].method == "GET"
assert semantic.apis[1].method == "POST"
assert semantic.pages[0].tables == ["Product"]
assert ir["kind"] == "PantherIR"
print("v0.5 tests passed")
