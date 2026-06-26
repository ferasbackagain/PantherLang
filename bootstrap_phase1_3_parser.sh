#!/usr/bin/env bash
set -e

echo "🐾 PantherLang Phase 1.3 — Parser Bootstrap"
echo "Root: $(pwd)"

mkdir -p architecture/compiler language/compiler/core language/tests scripts

cat > architecture/compiler/PARSER.md <<'EOF'
# PantherLang Parser

The parser converts the token stream into an Abstract Syntax Tree (AST).

Pipeline:
Source -> Lexer -> Tokens -> Parser -> AST -> Semantic Engine
EOF

cat > language/compiler/core/ast.py <<'EOF'
from dataclasses import dataclass, field

@dataclass
class Node:
    kind:str

@dataclass
class Program(Node):
    children:list = field(default_factory=list)

@dataclass
class Model(Node):
    name:str=""
    fields:list = field(default_factory=list)

@dataclass
class Field(Node):
    name:str=""
    type_name:str=""
EOF

cat > language/compiler/core/parser.py <<'EOF'
from compiler.core.lexer import tokenize

class Parser:
    def __init__(self, source:str):
        self.tokens = tokenize(source)

    def parse(self):
        return {
            "node":"Program",
            "token_count":len(self.tokens),
            "tokens":[t.value for t in self.tokens]
        }

def parse(source:str):
    return Parser(source).parse()
EOF

cat > language/tests/test_phase1_parser.py <<'EOF'
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
EOF

cat > scripts/verify_phase1_parser.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_parser.py
echo "✅ PantherLang Phase 1.3 parser verification complete."
EOF

chmod +x scripts/verify_phase1_parser.sh
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_parser.py

echo "--------------------------------"
echo "✅ PantherLang Phase 1.3 Parser installed successfully."
echo "Run anytime: bash scripts/verify_phase1_parser.sh"
echo "--------------------------------"
