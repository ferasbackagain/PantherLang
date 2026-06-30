from language.compiler.core.lexer import tokenize
from language.compiler.core.tokens import TokenType


source = '''
app PantherStore {
    model Product {
        id: uuid
        title: string required
        price: decimal
    }
}
'''

tokens = tokenize(source)
values = [token.value for token in tokens]

assert "app" in values
assert "PantherStore" in values
assert "model" in values
assert "Product" in values
assert "uuid" in values
assert "string" in values
assert "decimal" in values
assert tokens[-1].type == TokenType.EOF

print("✅ Phase 1.2 lexer tests passed.")
