from language.compiler.core.parser import parse

src="""
app Demo {
 model Product {
   id: uuid
 }
}
"""

tree=parse(src)
assert tree["node"]=="Program"
assert "Demo" in tree["tokens"]
assert "Product" in tree["tokens"]
print("✅ Phase 1.3 parser tests passed.")
