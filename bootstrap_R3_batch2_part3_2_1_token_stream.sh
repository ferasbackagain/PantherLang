#!/usr/bin/env bash
set -Eeuo pipefail

PART_ID="R3_BATCH2_PART3_2_1_TOKEN_STREAM"
PART_NAME="R3 Batch 2 Part 3.2.1 - Token Stream"
STAMP="$(date +%Y%m%d_%H%M%S)"
ROOT="$(pwd)"
BACKUP_DIR=".panther/backups/${PART_ID}_${STAMP}"
MANIFEST_DIR=".panther/manifests"
REPORT_DIR="docs/compiler_runtime/reports"
MANIFEST_FILE="${MANIFEST_DIR}/r3_batch2_part3_2_1_token_stream_manifest.json"
REPORT_FILE="${REPORT_DIR}/r3_batch2_part3_2_1_token_stream_report.md"

printf '\n== %s ==\n' "$PART_NAME"
printf 'Project root: %s\n' "$ROOT"

if [[ ! -d "compiler" || ! -d "tests" ]]; then
  echo "ERROR: Run this script from the PantherLang project root."
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$MANIFEST_DIR" "$REPORT_DIR" compiler/parser tests/R3_compiler_runtime docs/compiler_runtime

backup_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$path")"
    cp -a "$path" "$BACKUP_DIR/$path"
  fi
}

backup_if_exists compiler/parser/__init__.py
backup_if_exists compiler/parser/token_stream.py
backup_if_exists compiler/parser/cursor.py
backup_if_exists compiler/parser/parse_error.py
backup_if_exists compiler/parser/parser_base.py
backup_if_exists tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py
backup_if_exists docs/compiler_runtime/r3_batch2_part3_2_1_token_stream.md
backup_if_exists "$MANIFEST_FILE"
backup_if_exists "$REPORT_FILE"

cat > compiler/parser/parse_error.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

from compiler.lexer import SourceLocation, Token, TokenKind


@dataclass(frozen=True)
class ParseDiagnostic:
    """Structured parser diagnostic used by TokenStream and parser stages."""

    message: str
    location: SourceLocation
    token_kind: TokenKind | None = None
    token_lexeme: str = ""
    expected: tuple[TokenKind | str, ...] = ()

    def to_dict(self) -> dict[str, object]:
        return {
            "message": self.message,
            "location": {
                "line": self.location.line,
                "column": self.location.column,
                "index": self.location.index,
            },
            "token_kind": self.token_kind.value if self.token_kind is not None else None,
            "token_lexeme": self.token_lexeme,
            "expected": [item.value if isinstance(item, TokenKind) else str(item) for item in self.expected],
        }


class ParseError(SyntaxError):
    """Parser exception with source-aware diagnostic payload."""

    def __init__(
        self,
        message: str,
        token: Token | None = None,
        expected: Iterable[TokenKind | str] = (),
        location: SourceLocation | None = None,
    ) -> None:
        if token is None and location is None:
            location = SourceLocation(line=1, column=1, index=0)
        final_location = token.location if token is not None else location
        assert final_location is not None
        expected_tuple = tuple(expected)
        self.token = token
        self.diagnostic = ParseDiagnostic(
            message=message,
            location=final_location,
            token_kind=token.kind if token is not None else None,
            token_lexeme=token.lexeme if token is not None else "",
            expected=expected_tuple,
        )
        suffix = f" at line {final_location.line}, column {final_location.column}"
        if expected_tuple:
            names = ", ".join(item.value if isinstance(item, TokenKind) else str(item) for item in expected_tuple)
            suffix += f"; expected {names}"
        super().__init__(message + suffix)

    def to_dict(self) -> dict[str, object]:
        return self.diagnostic.to_dict()
PY

cat > compiler/parser/cursor.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass


@dataclass
class TokenCursor:
    """Mutable cursor used by TokenStream for deterministic parser navigation."""

    position: int = 0

    def save(self) -> int:
        return self.position

    def restore(self, checkpoint: int) -> None:
        if checkpoint < 0:
            raise ValueError("TokenCursor checkpoint cannot be negative")
        self.position = checkpoint

    def advance(self, amount: int = 1) -> int:
        if amount < 0:
            raise ValueError("TokenCursor cannot advance by a negative amount")
        self.position += amount
        return self.position

    def rewind(self, amount: int = 1) -> int:
        if amount < 0:
            raise ValueError("TokenCursor cannot rewind by a negative amount")
        self.position = max(0, self.position - amount)
        return self.position
PY

cat > compiler/parser/token_stream.py <<'PY'
from __future__ import annotations

from contextlib import contextmanager
from typing import Iterator, Sequence

from compiler.lexer import Token, TokenKind, lex_source

from .cursor import TokenCursor
from .parse_error import ParseError


class TokenStream:
    """Parser-facing token navigation layer over lexer output.

    The stream is intentionally small and strict: it guarantees an EOF token,
    clamps lookahead safely, and exposes checkpoint/rollback so recursive descent
    parser stages can speculate without corrupting state.
    """

    def __init__(self, tokens: Sequence[Token], *, source_name: str = "<memory>") -> None:
        if not tokens:
            raise ValueError("TokenStream requires at least an EOF token")
        self.tokens: tuple[Token, ...] = tuple(tokens)
        if self.tokens[-1].kind is not TokenKind.EOF:
            raise ValueError("TokenStream must end with TokenKind.EOF")
        self.cursor = TokenCursor(0)
        self.source_name = source_name

    @classmethod
    def from_source(cls, source: str, *, source_name: str = "<memory>") -> "TokenStream":
        return cls(lex_source(source), source_name=source_name)

    @property
    def position(self) -> int:
        return self.cursor.position

    @property
    def current(self) -> Token:
        return self.peek(0)

    @property
    def previous(self) -> Token:
        index = max(0, min(self.position - 1, len(self.tokens) - 1))
        return self.tokens[index]

    def __len__(self) -> int:
        return len(self.tokens)

    def __iter__(self) -> Iterator[Token]:
        return iter(self.tokens)

    def is_at_end(self) -> bool:
        return self.current.kind is TokenKind.EOF

    def peek(self, offset: int = 0) -> Token:
        if offset < 0:
            raise ValueError("TokenStream.peek offset cannot be negative")
        index = min(self.position + offset, len(self.tokens) - 1)
        return self.tokens[index]

    def check(self, *kinds: TokenKind) -> bool:
        return bool(kinds) and self.current.kind in kinds

    def check_next(self, *kinds: TokenKind) -> bool:
        return bool(kinds) and self.peek(1).kind in kinds

    def advance(self) -> Token:
        token = self.current
        if not self.is_at_end():
            self.cursor.advance()
        return token

    def match(self, *kinds: TokenKind) -> Token | None:
        if self.check(*kinds):
            return self.advance()
        return None

    def consume(self, kind: TokenKind, message: str | None = None) -> Token:
        if self.check(kind):
            return self.advance()
        found = self.current
        msg = message or f"Expected {kind.value}, found {found.kind.value}"
        raise ParseError(msg, token=found, expected=(kind,))

    def consume_any(self, kinds: Sequence[TokenKind], message: str | None = None) -> Token:
        if not kinds:
            raise ValueError("consume_any requires at least one TokenKind")
        if self.check(*kinds):
            return self.advance()
        found = self.current
        expected = tuple(kinds)
        msg = message or "Expected one of " + ", ".join(kind.value for kind in expected)
        raise ParseError(msg, token=found, expected=expected)

    def checkpoint(self) -> int:
        return self.cursor.save()

    def rollback(self, checkpoint: int) -> None:
        if checkpoint >= len(self.tokens):
            checkpoint = len(self.tokens) - 1
        self.cursor.restore(checkpoint)

    @contextmanager
    def speculative(self) -> Iterator["TokenStream"]:
        checkpoint = self.checkpoint()
        try:
            yield self
        except Exception:
            self.rollback(checkpoint)
            raise

    def slice_kinds(self, start: int = 0, end: int | None = None) -> tuple[TokenKind, ...]:
        return tuple(token.kind for token in self.tokens[start:end])

    def remaining_kinds(self) -> tuple[TokenKind, ...]:
        return self.slice_kinds(self.position)
PY

cat > compiler/parser/parser_base.py <<'PY'
from __future__ import annotations

from compiler.lexer import Token, TokenKind

from .parse_error import ParseError
from .token_stream import TokenStream


class ParserBase:
    """Shared recursive-descent parser utilities for upcoming parser segments."""

    def __init__(self, stream: TokenStream):
        self.stream = stream
        self.errors: list[ParseError] = []

    @classmethod
    def from_source(cls, source: str, *, source_name: str = "<memory>"):
        return cls(TokenStream.from_source(source, source_name=source_name))

    @property
    def current(self) -> Token:
        return self.stream.current

    @property
    def previous(self) -> Token:
        return self.stream.previous

    def is_at_end(self) -> bool:
        return self.stream.is_at_end()

    def peek(self, offset: int = 0) -> Token:
        return self.stream.peek(offset)

    def check(self, *kinds: TokenKind) -> bool:
        return self.stream.check(*kinds)

    def check_next(self, *kinds: TokenKind) -> bool:
        return self.stream.check_next(*kinds)

    def advance(self) -> Token:
        return self.stream.advance()

    def match(self, *kinds: TokenKind) -> Token | None:
        return self.stream.match(*kinds)

    def consume(self, kind: TokenKind, message: str | None = None) -> Token:
        return self.stream.consume(kind, message)

    def consume_any(self, kinds: tuple[TokenKind, ...] | list[TokenKind], message: str | None = None) -> Token:
        return self.stream.consume_any(kinds, message)

    def error(self, message: str, token: Token | None = None, expected: tuple[TokenKind | str, ...] = ()) -> ParseError:
        err = ParseError(message, token=token or self.current, expected=expected)
        self.errors.append(err)
        return err

    def synchronize(self) -> None:
        """Move to a likely statement boundary after a parser error."""
        if not self.is_at_end():
            self.advance()
        boundaries = {
            TokenKind.PANTHER,
            TokenKind.MAIN,
            TokenKind.PRINT,
            TokenKind.RETURN,
            TokenKind.ROUTE,
            TokenKind.GET,
            TokenKind.POST,
            TokenKind.TEST,
        }
        while not self.is_at_end():
            if self.previous.kind is TokenKind.SEMICOLON:
                return
            if self.current.kind in boundaries:
                return
            self.advance()
PY

cat > compiler/parser/__init__.py <<'PY'
"""PantherLang recursive-descent parser package."""

from .cursor import TokenCursor
from .parse_error import ParseDiagnostic, ParseError
from .parser_base import ParserBase
from .token_stream import TokenStream

__all__ = [
    "TokenCursor",
    "ParseDiagnostic",
    "ParseError",
    "ParserBase",
    "TokenStream",
]
PY

cat > tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py <<'PY'
import pytest

from compiler.lexer import TokenKind, lex_source
from compiler.parser import ParseError, ParserBase, TokenCursor, TokenStream


def test_token_stream_from_source_tracks_current_and_eof():
    stream = TokenStream.from_source('panther main { print("Hello") }')
    assert stream.current.kind is TokenKind.PANTHER
    assert stream.peek(1).kind is TokenKind.MAIN
    assert stream.peek(100).kind is TokenKind.EOF
    assert stream.slice_kinds()[-1] is TokenKind.EOF


def test_advance_match_consume_and_previous():
    stream = TokenStream.from_source('panther main')
    first = stream.advance()
    assert first.kind is TokenKind.PANTHER
    assert stream.previous.kind is TokenKind.PANTHER
    assert stream.match(TokenKind.MAIN).kind is TokenKind.MAIN
    assert stream.is_at_end()
    assert stream.advance().kind is TokenKind.EOF
    assert stream.position == len(stream.tokens) - 1


def test_checkpoint_and_rollback_support_parser_speculation():
    stream = TokenStream.from_source('panther main { }')
    checkpoint = stream.checkpoint()
    stream.consume(TokenKind.PANTHER)
    stream.consume(TokenKind.MAIN)
    assert stream.position == 2
    stream.rollback(checkpoint)
    assert stream.position == 0
    assert stream.current.kind is TokenKind.PANTHER


def test_consume_reports_structured_parse_error():
    stream = TokenStream.from_source('panther main')
    with pytest.raises(ParseError) as exc:
        stream.consume(TokenKind.PRINT)
    payload = exc.value.to_dict()
    assert payload["token_kind"] == "PANTHER"
    assert payload["expected"] == ["PRINT"]
    assert payload["location"]["line"] == 1


def test_parser_base_delegates_token_navigation():
    parser = ParserBase.from_source('panther main { print("Hello") }')
    assert parser.check(TokenKind.PANTHER)
    parser.consume(TokenKind.PANTHER)
    parser.consume(TokenKind.MAIN)
    parser.consume(TokenKind.LEFT_BRACE)
    assert parser.match(TokenKind.PRINT).kind is TokenKind.PRINT
    assert parser.current.kind is TokenKind.LEFT_PAREN


def test_token_cursor_save_restore_and_bounds():
    cursor = TokenCursor()
    assert cursor.advance(3) == 3
    mark = cursor.save()
    assert cursor.rewind(2) == 1
    cursor.restore(mark)
    assert cursor.position == 3
    with pytest.raises(ValueError):
        cursor.restore(-1)


def test_token_stream_requires_eof_guard():
    tokens = lex_source('panther main')[:-1]
    with pytest.raises(ValueError):
        TokenStream(tokens)


def test_synchronize_moves_to_statement_boundary():
    parser = ParserBase.from_source('value + + print("ok")')
    parser.synchronize()
    assert parser.current.kind in {TokenKind.PRINT, TokenKind.EOF}
PY

cat > docs/compiler_runtime/r3_batch2_part3_2_1_token_stream.md <<'MD'
# R3 Batch 2 Part 3.2.1 — Token Stream

This segment introduces the parser-facing token navigation foundation for the PantherLang recursive-descent parser.

## Delivered Files

- `compiler/parser/token_stream.py`
- `compiler/parser/cursor.py`
- `compiler/parser/parse_error.py`
- `compiler/parser/parser_base.py`
- `compiler/parser/__init__.py`
- `tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py`

## Capabilities

- EOF-guarded token stream over lexer output.
- Safe lookahead with clamped EOF behavior.
- `advance`, `match`, `consume`, `consume_any` parser primitives.
- Checkpoint and rollback for recursive-descent speculation.
- Structured `ParseError` diagnostics with source location and expected tokens.
- `ParserBase` delegates navigation and provides synchronization for upcoming parser segments.

## Next Segment

R3 Batch 2 Part 3.2.2 — Parser Infrastructure.
MD

python3 - <<'PY'
import json
from datetime import datetime, timezone
from pathlib import Path
manifest = {
    "part_id": "R3_BATCH2_PART3_2_1_TOKEN_STREAM",
    "part_name": "R3 Batch 2 Part 3.2.1 - Token Stream",
    "status": "IMPLEMENTED_PENDING_LOCAL_VERIFICATION",
    "timestamp_utc": datetime.now(timezone.utc).isoformat(),
    "files_added_or_updated": [
        "compiler/parser/token_stream.py",
        "compiler/parser/cursor.py",
        "compiler/parser/parse_error.py",
        "compiler/parser/parser_base.py",
        "compiler/parser/__init__.py",
        "tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py",
        "docs/compiler_runtime/r3_batch2_part3_2_1_token_stream.md",
        ".panther/manifests/r3_batch2_part3_2_1_token_stream_manifest.json",
        "docs/compiler_runtime/reports/r3_batch2_part3_2_1_token_stream_report.md",
    ],
    "verification_commands": [
        "python3 -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q",
        "python3 -m pytest tests/R3_compiler_runtime/test_r3_batch2_part2_lexer_foundation.py tests/R3_compiler_runtime/test_r3_batch2_part3_1_ast_definitions.py tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q",
    ],
    "next_part": "R3 Batch 2 Part 3.2.2 - Parser Infrastructure",
}
Path(".panther/manifests/r3_batch2_part3_2_1_token_stream_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
PY

cat > "$REPORT_FILE" <<'MD'
# R3 Batch 2 Part 3.2.1 — Token Stream Engineering Report

## Result

Implemented the parser token stream foundation required before recursive-descent parser infrastructure.

## Scope

- Token cursor navigation.
- EOF-safe token stream.
- Parser checkpoint/rollback support.
- Structured parse diagnostics.
- ParserBase primitives for future parser stages.
- Unit tests for stream navigation, error reporting, rollback, and synchronization.

## Verification

Run by this bootstrap:

```bash
python3 -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q
python3 -m pytest tests/R3_compiler_runtime/test_r3_batch2_part2_lexer_foundation.py tests/R3_compiler_runtime/test_r3_batch2_part3_1_ast_definitions.py tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q
```

## Next

Continue to R3 Batch 2 Part 3.2.2 — Parser Infrastructure.
MD

printf '\nRunning focused tests...\n'
python3 -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q

printf '\nRunning lexer + AST + token stream regression slice...\n'
python3 -m pytest \
  tests/R3_compiler_runtime/test_r3_batch2_part2_lexer_foundation.py \
  tests/R3_compiler_runtime/test_r3_batch2_part3_1_ast_definitions.py \
  tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py \
  -q

python3 - <<'PY'
import json
from datetime import datetime, timezone
from pathlib import Path
path = Path(".panther/manifests/r3_batch2_part3_2_1_token_stream_manifest.json")
manifest = json.loads(path.read_text(encoding="utf-8"))
manifest["status"] = "PASSED_LOCAL_VERIFICATION"
manifest["verified_at_utc"] = datetime.now(timezone.utc).isoformat()
path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
PY

printf '\n%s completed successfully.\n' "$PART_NAME"
printf 'Manifest: %s\n' "$MANIFEST_FILE"
printf 'Report: %s\n' "$REPORT_FILE"
printf 'Backup: %s\n' "$BACKUP_DIR"
printf 'Next: R3 Batch 2 Part 3.2.2 - Parser Infrastructure\n'
