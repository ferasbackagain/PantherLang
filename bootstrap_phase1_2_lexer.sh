#!/usr/bin/env bash
set -e

echo "🐾 PantherLang Phase 1.2 — Lexer Bootstrap"
echo "Root: $(pwd)"

mkdir -p language/compiler/core language/tests architecture/compiler docs scripts

cat > architecture/compiler/LEXER.md <<'EOF'
# PantherLang Lexer — Phase 1.2

## Purpose
The lexer converts Panther source code into a stream of tokens.

## Input
A `.panther` source file.

## Output
A list of tokens with:
- type
- value
- line
- column

## Supported Tokens
- Keywords
- Identifiers
- Strings
- Numbers
- Symbols
- Comments
- EOF

## Design Rules
1. The lexer must be deterministic.
2. Every token must preserve source location.
3. Unknown characters must produce clear diagnostics.
4. The lexer must be simple enough for AI systems to understand and generate.
EOF

cat > language/compiler/core/tokens.py <<'EOF'
from dataclasses import dataclass


@dataclass(frozen=True)
class Token:
    type: str
    value: str
    line: int
    column: int

    def __repr__(self):
        return f"{self.type}({self.value!r})@{self.line}:{self.column}"


class TokenType:
    KEYWORD = "KEYWORD"
    IDENTIFIER = "IDENTIFIER"
    STRING = "STRING"
    NUMBER = "NUMBER"
    SYMBOL = "SYMBOL"
    EOF = "EOF"
EOF

cat > language/compiler/core/lexer.py <<'EOF'
from compiler.core.tokens import Token, TokenType


KEYWORDS = {
    "app", "module", "package", "import", "from", "as",
    "let", "var", "const", "fn", "return",
    "if", "else", "match", "case", "for", "while",
    "break", "continue", "try", "catch", "throw",
    "error", "result", "model", "entity", "struct",
    "enum", "interface", "data", "api", "page", "ui",
    "workflow", "agent", "task", "event", "service",
    "async", "await", "capabilities", "allow", "deny",
    "security", "policy", "permission", "secret",
    "deploy", "target", "runtime", "true", "false",
    "null", "void", "required", "public", "create",
}

SYMBOLS = {
    "{", "}", "(", ")", "[", "]",
    ":", ",", ".", "=", "<", ">", "/", "?",
    "+", "-", "*", "!", "|",
}


class LexerError(Exception):
    pass


class Lexer:
    def __init__(self, source: str):
        self.source = source
        self.index = 0
        self.line = 1
        self.column = 1
        self.tokens = []

    def current(self):
        if self.index >= len(self.source):
            return "\0"
        return self.source[self.index]

    def advance(self):
        ch = self.current()
        self.index += 1
        if ch == "\n":
            self.line += 1
            self.column = 1
        else:
            self.column += 1
        return ch

    def add(self, token_type, value, line, column):
        self.tokens.append(Token(token_type, value, line, column))

    def tokenize(self):
        while self.current() != "\0":
            ch = self.current()

            if ch in " \t\r":
                self.advance()
                continue

            if ch == "\n":
                self.advance()
                continue

            if ch == "#":
                self.skip_comment()
                continue

            if ch == '"':
                self.read_string()
                continue

            if ch.isdigit():
                self.read_number()
                continue

            if ch.isalpha() or ch == "_":
                self.read_identifier()
                continue

            if ch in SYMBOLS:
                line, col = self.line, self.column
                self.add(TokenType.SYMBOL, ch, line, col)
                self.advance()
                continue

            raise LexerError(f"Unexpected character {ch!r} at {self.line}:{self.column}")

        self.tokens.append(Token(TokenType.EOF, "", self.line, self.column))
        return self.tokens

    def skip_comment(self):
        while self.current() not in ("\n", "\0"):
            self.advance()

    def read_string(self):
        line, col = self.line, self.column
        self.advance()
        value = ""

        while self.current() not in ('"', "\0"):
            if self.current() == "\n":
                raise LexerError(f"Unterminated string at {line}:{col}")
            value += self.advance()

        if self.current() != '"':
            raise LexerError(f"Unterminated string at {line}:{col}")

        self.advance()
        self.add(TokenType.STRING, value, line, col)

    def read_number(self):
        line, col = self.line, self.column
        value = ""

        while self.current().isdigit() or self.current() == ".":
            value += self.advance()

        self.add(TokenType.NUMBER, value, line, col)

    def read_identifier(self):
        line, col = self.line, self.column
        value = ""

        while self.current().isalnum() or self.current() == "_":
            value += self.advance()

        token_type = TokenType.KEYWORD if value in KEYWORDS else TokenType.IDENTIFIER
        self.add(token_type, value, line, col)


def tokenize(source: str):
    return Lexer(source).tokenize()
EOF

cat > language/tests/test_phase1_lexer.py <<'EOF'
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
EOF

cat > scripts/verify_phase1_lexer.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_lexer.py
echo "✅ PantherLang Phase 1.2 lexer verification complete."
EOF

chmod +x scripts/verify_phase1_lexer.sh

PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_lexer.py

echo "--------------------------------"
echo "✅ PantherLang Phase 1.2 Lexer installed successfully."
echo "Run anytime: bash scripts/verify_phase1_lexer.sh"
echo "--------------------------------"
