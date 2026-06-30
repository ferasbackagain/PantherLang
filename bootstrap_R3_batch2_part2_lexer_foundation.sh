#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Batch 2 - Real Language Core"
echo " Part 2 - Lexer Foundation"
echo "============================================================"

ROOT="$(pwd)"
R32="$ROOT/.panther/R3_compiler_runtime"
REPORTS="$ROOT/reports/R3_compiler_runtime"
BACKUP="$ROOT/.panther/backups/R3_batch2_part2_lexer_foundation_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R32" "$REPORTS" "$BACKUP"

fail(){ echo "[R3-B2-P2][ERROR] $1" >&2; exit 1; }

echo "[1/12] Pre-flight gates..."
[ -d ".git" ] || fail "Run from PantherLang project root."
[ -f "$R32/status_batch2_part1_compiler_runtime_contract.json" ] || fail "Run R3 Batch 2 Part 1 first."
[ -d compiler/runtime_contract ] || fail "compiler/runtime_contract missing."

echo "[2/12] Safety backup..."
[ -d compiler/lexer ] && cp -a compiler/lexer "$BACKUP/compiler_lexer" || true
[ -d tests/R3_compiler_runtime ] && cp -a tests/R3_compiler_runtime "$BACKUP/tests_R3_compiler_runtime" || true
[ -d docs/compiler_runtime ] && cp -a docs/compiler_runtime "$BACKUP/docs_compiler_runtime" || true

echo "[3/12] Baseline regression..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q
python3 -m pytest tests/R3_project_system -q
python3 -m pytest tests/R3_compiler_runtime -q

echo "[4/12] Creating Lexer package..."
mkdir -p compiler/lexer docs/compiler_runtime tests/R3_compiler_runtime

cat > compiler/lexer/__init__.py <<'PY'
from .tokens import Token, TokenKind, SourceLocation, LexerError
from .lexer import PantherLexer, lex_source

__all__ = ["Token", "TokenKind", "SourceLocation", "LexerError", "PantherLexer", "lex_source"]
PY

cat > compiler/lexer/tokens.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class TokenKind(str, Enum):
    EOF = "EOF"
    UNKNOWN = "UNKNOWN"
    IDENTIFIER = "IDENTIFIER"
    NUMBER = "NUMBER"
    STRING = "STRING"
    PANTHER = "PANTHER"
    MAIN = "MAIN"
    WEB = "WEB"
    API = "API"
    AI = "AI"
    TEST = "TEST"
    PRINT = "PRINT"
    RETURN = "RETURN"
    ROUTE = "ROUTE"
    GET = "GET"
    POST = "POST"
    TRUE = "TRUE"
    FALSE = "FALSE"
    ASSERT = "ASSERT"
    PROMPT = "PROMPT"
    LEFT_BRACE = "LEFT_BRACE"
    RIGHT_BRACE = "RIGHT_BRACE"
    LEFT_PAREN = "LEFT_PAREN"
    RIGHT_PAREN = "RIGHT_PAREN"
    LEFT_BRACKET = "LEFT_BRACKET"
    RIGHT_BRACKET = "RIGHT_BRACKET"
    COMMA = "COMMA"
    COLON = "COLON"
    SEMICOLON = "SEMICOLON"
    DOT = "DOT"
    EQUAL = "EQUAL"
    PLUS = "PLUS"
    MINUS = "MINUS"
    STAR = "STAR"
    SLASH = "SLASH"
    BANG = "BANG"
    EQUAL_EQUAL = "EQUAL_EQUAL"
    BANG_EQUAL = "BANG_EQUAL"
    GREATER = "GREATER"
    GREATER_EQUAL = "GREATER_EQUAL"
    LESS = "LESS"
    LESS_EQUAL = "LESS_EQUAL"
    ARROW = "ARROW"


KEYWORDS = {
    "panther": TokenKind.PANTHER,
    "main": TokenKind.MAIN,
    "web": TokenKind.WEB,
    "api": TokenKind.API,
    "ai": TokenKind.AI,
    "test": TokenKind.TEST,
    "print": TokenKind.PRINT,
    "return": TokenKind.RETURN,
    "route": TokenKind.ROUTE,
    "get": TokenKind.GET,
    "post": TokenKind.POST,
    "true": TokenKind.TRUE,
    "false": TokenKind.FALSE,
    "assert": TokenKind.ASSERT,
    "prompt": TokenKind.PROMPT,
}


@dataclass(frozen=True)
class SourceLocation:
    line: int
    column: int
    index: int


@dataclass(frozen=True)
class Token:
    kind: TokenKind
    lexeme: str
    literal: object | None
    location: SourceLocation


class LexerError(Exception):
    def __init__(self, message: str, location: SourceLocation):
        super().__init__(f"{message} at line {location.line}, column {location.column}")
        self.message = message
        self.location = location
PY

cat > compiler/lexer/lexer.py <<'PY'
from __future__ import annotations

from .tokens import KEYWORDS, LexerError, SourceLocation, Token, TokenKind


class PantherLexer:
    def __init__(self, source: str):
        self.source = source
        self.tokens: list[Token] = []
        self.start = 0
        self.current = 0
        self.line = 1
        self.column = 1
        self.token_line = 1
        self.token_column = 1
        self.token_index = 0

    def scan_tokens(self) -> list[Token]:
        while not self._is_at_end():
            self.start = self.current
            self.token_line = self.line
            self.token_column = self.column
            self.token_index = self.current
            self._scan_token()
        self.tokens.append(Token(TokenKind.EOF, "", None, SourceLocation(self.line, self.column, self.current)))
        return self.tokens

    def _scan_token(self) -> None:
        ch = self._advance()
        single = {
            "{": TokenKind.LEFT_BRACE, "}": TokenKind.RIGHT_BRACE,
            "(": TokenKind.LEFT_PAREN, ")": TokenKind.RIGHT_PAREN,
            "[": TokenKind.LEFT_BRACKET, "]": TokenKind.RIGHT_BRACKET,
            ",": TokenKind.COMMA, ":": TokenKind.COLON,
            ";": TokenKind.SEMICOLON, ".": TokenKind.DOT,
            "+": TokenKind.PLUS, "*": TokenKind.STAR,
        }
        if ch in single:
            self._add_token(single[ch])
        elif ch == "-":
            self._add_token(TokenKind.ARROW if self._match(">") else TokenKind.MINUS)
        elif ch == "!":
            self._add_token(TokenKind.BANG_EQUAL if self._match("=") else TokenKind.BANG)
        elif ch == "=":
            self._add_token(TokenKind.EQUAL_EQUAL if self._match("=") else TokenKind.EQUAL)
        elif ch == "<":
            self._add_token(TokenKind.LESS_EQUAL if self._match("=") else TokenKind.LESS)
        elif ch == ">":
            self._add_token(TokenKind.GREATER_EQUAL if self._match("=") else TokenKind.GREATER)
        elif ch == "/":
            if self._match("/"):
                while self._peek() != "\n" and not self._is_at_end():
                    self._advance()
            else:
                self._add_token(TokenKind.SLASH)
        elif ch in (" ", "\r", "\t"):
            return
        elif ch == "\n":
            return
        elif ch == '"':
            self._string()
        elif ch.isdigit():
            self._number()
        elif self._is_identifier_start(ch):
            self._identifier()
        else:
            raise LexerError(f"Unexpected character {ch!r}", self._location())

    def _identifier(self) -> None:
        while self._is_identifier_part(self._peek()):
            self._advance()
        text = self.source[self.start:self.current]
        self._add_token(KEYWORDS.get(text, TokenKind.IDENTIFIER))

    def _number(self) -> None:
        while self._peek().isdigit():
            self._advance()
        if self._peek() == "." and self._peek_next().isdigit():
            self._advance()
            while self._peek().isdigit():
                self._advance()
        text = self.source[self.start:self.current]
        self._add_token(TokenKind.NUMBER, float(text) if "." in text else int(text))

    def _string(self) -> None:
        chars: list[str] = []
        while not self._is_at_end() and self._peek() != '"':
            ch = self._advance()
            if ch == "\\":
                if self._is_at_end():
                    raise LexerError("Unterminated string escape", self._location())
                esc = self._advance()
                chars.append({"n": "\n", "t": "\t", '"': '"', "\\": "\\"}.get(esc, esc))
            else:
                chars.append(ch)
        if self._is_at_end():
            raise LexerError("Unterminated string", self._location())
        self._advance()
        self._add_token(TokenKind.STRING, "".join(chars))

    def _add_token(self, kind: TokenKind, literal: object | None = None) -> None:
        self.tokens.append(Token(
            kind=kind,
            lexeme=self.source[self.start:self.current],
            literal=literal,
            location=SourceLocation(self.token_line, self.token_column, self.token_index),
        ))

    def _advance(self) -> str:
        ch = self.source[self.current]
        self.current += 1
        if ch == "\n":
            self.line += 1
            self.column = 1
        else:
            self.column += 1
        return ch

    def _match(self, expected: str) -> bool:
        if self._is_at_end() or self.source[self.current] != expected:
            return False
        self._advance()
        return True

    def _peek(self) -> str:
        return "\0" if self._is_at_end() else self.source[self.current]

    def _peek_next(self) -> str:
        return "\0" if self.current + 1 >= len(self.source) else self.source[self.current + 1]

    def _is_at_end(self) -> bool:
        return self.current >= len(self.source)

    def _location(self) -> SourceLocation:
        return SourceLocation(self.line, self.column, self.current)

    @staticmethod
    def _is_identifier_start(ch: str) -> bool:
        return ch.isalpha() or ch == "_"

    @staticmethod
    def _is_identifier_part(ch: str) -> bool:
        return ch.isalnum() or ch == "_"


def lex_source(source: str) -> list[Token]:
    return PantherLexer(source).scan_tokens()
PY

echo "[5/12] Creating CLI lexer inspector..."
cat > compiler/lexer/panther_lex.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from compiler.lexer import LexerError, lex_source


def main() -> int:
    parser = argparse.ArgumentParser(description="Lex PantherLang source and print tokens.")
    parser.add_argument("source_file")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    source = Path(args.source_file).read_text(encoding="utf-8")
    try:
        tokens = lex_source(source)
    except LexerError as exc:
        if args.json:
            print(json.dumps({"ok": False, "error": exc.message, "line": exc.location.line, "column": exc.location.column}, indent=2))
            return 1
        raise
    if args.json:
        print(json.dumps({"ok": True, "tokens": [
            {"kind": t.kind.value, "lexeme": t.lexeme, "literal": t.literal, "line": t.location.line, "column": t.location.column}
            for t in tokens
        ]}, indent=2))
    else:
        for t in tokens:
            print(f"{t.location.line}:{t.location.column} {t.kind.value} {t.lexeme!r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x compiler/lexer/panther_lex.py

echo "[6/12] Documentation..."
cat > docs/compiler_runtime/LEXER_FOUNDATION.md <<'EOF'
# PantherLang Lexer Foundation

The lexer converts PantherLang source into tokens.

Supports keywords, identifiers, numbers, strings, comments, delimiters, operators, line/column tracking, and lexer errors.

Example:

```panther
panther main {
    print("Hello World")
}
```
EOF

echo "[7/12] Creating lexer tests..."
cat > tests/R3_compiler_runtime/test_r3_batch2_part2_lexer_foundation.py <<'PY'
import json
import subprocess
import sys
from pathlib import Path

import pytest

from compiler.lexer import LexerError, TokenKind, lex_source


def kinds(source: str):
    return [token.kind for token in lex_source(source)]


def test_lex_hello_world_program():
    tokens = lex_source('panther main { print("Hello World") }')
    assert [t.kind for t in tokens] == [
        TokenKind.PANTHER, TokenKind.MAIN, TokenKind.LEFT_BRACE,
        TokenKind.PRINT, TokenKind.LEFT_PAREN, TokenKind.STRING,
        TokenKind.RIGHT_PAREN, TokenKind.RIGHT_BRACE, TokenKind.EOF,
    ]
    assert tokens[5].literal == "Hello World"


def test_lex_api_route():
    ks = kinds('panther api { get "/health" { return { "status": "ok" } } }')
    assert TokenKind.API in ks
    assert TokenKind.GET in ks
    assert TokenKind.RETURN in ks
    assert ks[-1] == TokenKind.EOF


def test_lex_numbers_identifiers_and_operators():
    tokens = lex_source('value = 42 + 3.5 != other')
    assert [t.kind for t in tokens] == [
        TokenKind.IDENTIFIER, TokenKind.EQUAL, TokenKind.NUMBER,
        TokenKind.PLUS, TokenKind.NUMBER, TokenKind.BANG_EQUAL,
        TokenKind.IDENTIFIER, TokenKind.EOF,
    ]
    assert tokens[2].literal == 42
    assert tokens[4].literal == 3.5


def test_comments_are_ignored_and_locations_are_tracked():
    tokens = lex_source('// comment\npanther main')
    assert tokens[0].kind == TokenKind.PANTHER
    assert tokens[0].location.line == 2
    assert tokens[0].location.column == 1


def test_unterminated_string_reports_error():
    with pytest.raises(LexerError) as exc:
        lex_source('print("hello)')
    assert "Unterminated string" in str(exc.value)


def test_lexer_cli_json(tmp_path):
    src = tmp_path / "hello.panther"
    src.write_text('panther main { print("Hello") }', encoding="utf-8")
    proc = subprocess.run([sys.executable, "compiler/lexer/panther_lex.py", str(src), "--json"], text=True, capture_output=True, check=True)
    data = json.loads(proc.stdout)
    assert data["ok"] is True
    assert data["tokens"][0]["kind"] == "PANTHER"
    assert data["tokens"][-1]["kind"] == "EOF"
PY

echo "[8/12] Validation..."
python3 -m py_compile compiler/lexer/__init__.py compiler/lexer/tokens.py compiler/lexer/lexer.py compiler/lexer/panther_lex.py tests/R3_compiler_runtime/test_r3_batch2_part2_lexer_foundation.py
python3 -m pytest tests/R3_compiler_runtime -q

echo "[9/12] Integration smoke with project template..."
TMPDIR="$(mktemp -d)"
python3 tools/project_wizard/panther_new.py lexer-smoke --template console --destination "$TMPDIR" --json >/tmp/panther_lexer_project.json
python3 compiler/lexer/panther_lex.py "$TMPDIR/lexer-smoke/src/main.panther" --json >/tmp/panther_lexer_tokens.json
python3 - <<'PY'
import json
from pathlib import Path
data = json.loads(Path("/tmp/panther_lexer_tokens.json").read_text())
assert data["ok"] is True
assert data["tokens"][0]["kind"] == "PANTHER"
print("✅ template lex smoke passed")
PY

echo "[10/12] Writing manifest..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone
root = Path.cwd()
r32 = root / ".panther/R3_compiler_runtime"
files = [
    "compiler/lexer/__init__.py",
    "compiler/lexer/tokens.py",
    "compiler/lexer/lexer.py",
    "compiler/lexer/panther_lex.py",
    "docs/compiler_runtime/LEXER_FOUNDATION.md",
    "tests/R3_compiler_runtime/test_r3_batch2_part2_lexer_foundation.py",
]
manifest = {
    "ok": True,
    "phase": "R3",
    "batch": "2",
    "part": "2",
    "name": "Lexer Foundation",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "runtime_modified": True,
    "features": ["token_kinds", "keyword_lexing", "identifier_lexing", "number_lexing", "string_lexing", "comments", "operators", "line_column_tracking", "lexer_cli"],
    "files": [{"path": f, "sha256": hashlib.sha256((root / f).read_bytes()).hexdigest(), "size": (root / f).stat().st_size} for f in files if (root / f).exists()],
    "next": "R3 Batch 2 Part 3 - Parser Foundation"
}
(r32 / "batch2_part2_lexer_foundation_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ manifest written")
PY

echo "[11/12] Writing report..."
cat > "$REPORTS/R3_BATCH2_PART2_LEXER_FOUNDATION.md" <<'EOF'
# R3 Batch 2 Part 2 - Lexer Foundation

## Status

PASSED

## Added

- PantherLexer
- TokenKind definitions
- SourceLocation tracking
- LexerError
- CLI lexer inspector
- Lexer documentation
- Unit tests
- Template smoke integration

## Next

R3 Batch 2 Part 3 - Parser Foundation.
EOF

echo "[12/12] Writing status..."
cat > "$R32/status_batch2_part2_lexer_foundation.json" <<'EOF'
{
  "ok": true,
  "phase": "R3",
  "batch": "2",
  "part": "2",
  "status": "PASSED",
  "name": "Lexer Foundation",
  "runtime_modified": true,
  "next": "R3 Batch 2 Part 3 - Parser Foundation"
}
EOF

echo "============================================================"
echo "✅ R3 Batch 2 Part 2 COMPLETE"
echo "✅ Lexer Foundation READY"
echo "Next: R3 Batch 2 Part 3 - Parser Foundation"
echo "============================================================"
