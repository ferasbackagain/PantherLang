#!/usr/bin/env bash
set -Eeuo pipefail

PART_ID="R3_BATCH2_PART3_2_2_PARSER_INFRASTRUCTURE"
PART_NAME="R3 Batch 2 Part 3.2.2 - Parser Infrastructure"
STAMP="$(date +%Y%m%d_%H%M%S)"
ROOT="$(pwd)"
BACKUP_DIR=".panther/backups/${PART_ID}_${STAMP}"
MANIFEST_DIR=".panther/manifests"
REPORT_DIR="docs/compiler_runtime/reports"
MANIFEST_FILE="${MANIFEST_DIR}/r3_batch2_part3_2_2_parser_infrastructure_manifest.json"
REPORT_FILE="${REPORT_DIR}/r3_batch2_part3_2_2_parser_infrastructure_report.md"

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
backup_if_exists compiler/parser/diagnostics.py
backup_if_exists compiler/parser/parser_context.py
backup_if_exists compiler/parser/parser_result.py
backup_if_exists compiler/parser/parser_base.py
backup_if_exists tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py
backup_if_exists docs/compiler_runtime/r3_batch2_part3_2_2_parser_infrastructure.md
backup_if_exists "$MANIFEST_FILE"
backup_if_exists "$REPORT_FILE"

if [[ ! -f compiler/parser/token_stream.py || ! -f compiler/parser/parse_error.py ]]; then
  echo "ERROR: Part 3.2.1 Token Stream is required before Part 3.2.2."
  exit 1
fi

cat > compiler/parser/diagnostics.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Iterable

from compiler.lexer import SourceLocation, Token, TokenKind


class DiagnosticSeverity(str, Enum):
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"


@dataclass(frozen=True)
class ParserDiagnostic:
    """Stable diagnostic record emitted by parser infrastructure."""

    message: str
    location: SourceLocation
    severity: DiagnosticSeverity = DiagnosticSeverity.ERROR
    token_kind: TokenKind | None = None
    token_lexeme: str = ""
    expected: tuple[TokenKind | str, ...] = ()
    code: str = "PARSER_ERROR"

    @classmethod
    def from_token(
        cls,
        message: str,
        token: Token,
        *,
        expected: Iterable[TokenKind | str] = (),
        severity: DiagnosticSeverity = DiagnosticSeverity.ERROR,
        code: str = "PARSER_ERROR",
    ) -> "ParserDiagnostic":
        return cls(
            message=message,
            location=token.location,
            severity=severity,
            token_kind=token.kind,
            token_lexeme=token.lexeme,
            expected=tuple(expected),
            code=code,
        )

    def to_dict(self) -> dict[str, object]:
        return {
            "code": self.code,
            "severity": self.severity.value,
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


@dataclass
class DiagnosticBag:
    """Collects parser diagnostics while keeping error policy centralized."""

    diagnostics: list[ParserDiagnostic] = field(default_factory=list)

    def add(self, diagnostic: ParserDiagnostic) -> ParserDiagnostic:
        self.diagnostics.append(diagnostic)
        return diagnostic

    def error(self, message: str, token: Token, *, expected: Iterable[TokenKind | str] = (), code: str = "PARSER_ERROR") -> ParserDiagnostic:
        return self.add(ParserDiagnostic.from_token(message, token, expected=expected, code=code))

    def warning(self, message: str, token: Token, *, code: str = "PARSER_WARNING") -> ParserDiagnostic:
        return self.add(ParserDiagnostic.from_token(message, token, severity=DiagnosticSeverity.WARNING, code=code))

    @property
    def has_errors(self) -> bool:
        return any(item.severity is DiagnosticSeverity.ERROR for item in self.diagnostics)

    def clear(self) -> None:
        self.diagnostics.clear()

    def to_list(self) -> list[dict[str, object]]:
        return [item.to_dict() for item in self.diagnostics]
PY

cat > compiler/parser/parser_context.py <<'PY'
from __future__ import annotations

from contextlib import contextmanager
from dataclasses import dataclass, field
from typing import Iterator

from compiler.lexer import TokenKind

from .diagnostics import DiagnosticBag
from .token_stream import TokenStream


@dataclass
class ParserContext:
    """Shared mutable parser context for recursive descent stages."""

    stream: TokenStream
    diagnostics: DiagnosticBag = field(default_factory=DiagnosticBag)
    panic_mode: bool = False

    def checkpoint(self) -> int:
        return self.stream.checkpoint()

    def rollback(self, checkpoint: int) -> None:
        self.stream.rollback(checkpoint)

    @contextmanager
    def speculative(self) -> Iterator[None]:
        """Rollback automatically unless the caller commits by exhausting normally with commit()."""
        checkpoint = self.checkpoint()
        marker = {"commit": False}

        def commit() -> None:
            marker["commit"] = True

        self.commit = commit  # type: ignore[attr-defined]
        try:
            yield
        finally:
            if not marker["commit"]:
                self.rollback(checkpoint)
            if hasattr(self, "commit"):
                delattr(self, "commit")

    def recover_to(self, *kinds: TokenKind) -> None:
        """Advance until a recovery boundary or EOF is reached."""
        self.panic_mode = True
        boundaries = set(kinds) or {
            TokenKind.SEMICOLON,
            TokenKind.RIGHT_BRACE,
            TokenKind.PANTHER,
            TokenKind.MAIN,
            TokenKind.PRINT,
            TokenKind.RETURN,
            TokenKind.ROUTE,
            TokenKind.GET,
            TokenKind.POST,
            TokenKind.TEST,
        }
        while not self.stream.is_at_end() and self.stream.current.kind not in boundaries:
            self.stream.advance()
        self.panic_mode = False
PY

cat > compiler/parser/parser_result.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Generic, TypeVar

from .diagnostics import ParserDiagnostic

T = TypeVar("T")


@dataclass(frozen=True)
class ParserResult(Generic[T]):
    """Uniform return object for parser entry points."""

    node: T | None = None
    diagnostics: tuple[ParserDiagnostic, ...] = field(default_factory=tuple)

    @property
    def ok(self) -> bool:
        return self.node is not None and not self.diagnostics

    @property
    def has_errors(self) -> bool:
        return bool(self.diagnostics)

    def to_dict(self) -> dict[str, object]:
        return {
            "ok": self.ok,
            "has_errors": self.has_errors,
            "diagnostics": [item.to_dict() for item in self.diagnostics],
        }
PY

cat > compiler/parser/parser_base.py <<'PY'
from __future__ import annotations

from typing import Callable, TypeVar

from compiler.lexer import Token, TokenKind

from .diagnostics import DiagnosticBag, ParserDiagnostic
from .parse_error import ParseError
from .parser_context import ParserContext
from .parser_result import ParserResult
from .token_stream import TokenStream

T = TypeVar("T")


class ParserBase:
    """Shared recursive-descent parser infrastructure.

    This layer owns parser state, diagnostics, recovery, optional parsing,
    speculation, and consistent ParserResult construction. Concrete parser
    stages should subclass this class instead of touching TokenStream directly.
    """

    def __init__(self, stream: TokenStream | ParserContext):
        if isinstance(stream, ParserContext):
            self.context = stream
        else:
            self.context = ParserContext(stream)
        self.stream = self.context.stream
        self.errors: list[ParseError] = []

    @classmethod
    def from_source(cls, source: str, *, source_name: str = "<memory>"):
        return cls(TokenStream.from_source(source, source_name=source_name))

    @property
    def diagnostics(self) -> DiagnosticBag:
        return self.context.diagnostics

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
        try:
            return self.stream.consume(kind, message)
        except ParseError as err:
            self.errors.append(err)
            self.diagnostics.error(err.diagnostic.message, err.token or self.current, expected=(kind,))
            raise

    def consume_any(self, kinds: tuple[TokenKind, ...] | list[TokenKind], message: str | None = None) -> Token:
        try:
            return self.stream.consume_any(kinds, message)
        except ParseError as err:
            self.errors.append(err)
            self.diagnostics.error(err.diagnostic.message, err.token or self.current, expected=tuple(kinds))
            raise

    def optional(self, parser: Callable[[], T]) -> T | None:
        """Try parser callable and rollback cleanly on ParseError."""
        checkpoint = self.stream.checkpoint()
        before_diag_count = len(self.diagnostics.diagnostics)
        before_error_count = len(self.errors)
        try:
            return parser()
        except ParseError:
            self.stream.rollback(checkpoint)
            del self.diagnostics.diagnostics[before_diag_count:]
            del self.errors[before_error_count:]
            return None

    def expect(self, kind: TokenKind, message: str | None = None) -> Token | None:
        """Non-throwing consume used by recovery-aware parser stages."""
        if self.check(kind):
            return self.advance()
        self.diagnostic(message or f"Expected {kind.value}", expected=(kind,))
        return None

    def diagnostic(
        self,
        message: str,
        *,
        token: Token | None = None,
        expected: tuple[TokenKind | str, ...] = (),
        code: str = "PARSER_ERROR",
    ) -> ParserDiagnostic:
        return self.diagnostics.error(message, token or self.current, expected=expected, code=code)

    def error(self, message: str, token: Token | None = None, expected: tuple[TokenKind | str, ...] = ()) -> ParseError:
        err = ParseError(message, token=token or self.current, expected=expected)
        self.errors.append(err)
        self.diagnostic(message, token=token or self.current, expected=expected)
        return err

    def recover_to(self, *kinds: TokenKind) -> None:
        self.context.recover_to(*kinds)

    def synchronize(self) -> None:
        """Move to a likely statement boundary after a parser error."""
        if not self.is_at_end():
            self.advance()
        self.recover_to()

    def result(self, node: T | None) -> ParserResult[T]:
        return ParserResult(node=node, diagnostics=tuple(self.diagnostics.diagnostics))
PY

cat > compiler/parser/__init__.py <<'PY'
"""PantherLang recursive-descent parser package."""

from .cursor import TokenCursor
from .diagnostics import DiagnosticBag, DiagnosticSeverity, ParserDiagnostic
from .parse_error import ParseDiagnostic, ParseError
from .parser_base import ParserBase
from .parser_context import ParserContext
from .parser_result import ParserResult
from .token_stream import TokenStream

__all__ = [
    "TokenCursor",
    "DiagnosticBag",
    "DiagnosticSeverity",
    "ParserDiagnostic",
    "ParseDiagnostic",
    "ParseError",
    "ParserBase",
    "ParserContext",
    "ParserResult",
    "TokenStream",
]
PY

cat > tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py <<'PY'
import pytest

from compiler.lexer import TokenKind
from compiler.parser import DiagnosticSeverity, ParserBase, ParserContext, ParserResult, TokenStream
from compiler.parser.diagnostics import DiagnosticBag


class DemoParser(ParserBase):
    def parse_panther_main_header(self):
        self.consume(TokenKind.PANTHER)
        self.consume(TokenKind.MAIN)
        return "header"


def test_parser_context_wraps_stream_and_checkpoints():
    stream = TokenStream.from_source("panther main { }")
    context = ParserContext(stream)
    mark = context.checkpoint()
    context.stream.advance()
    context.stream.advance()
    assert context.stream.current.kind is TokenKind.LEFT_BRACE
    context.rollback(mark)
    assert context.stream.current.kind is TokenKind.PANTHER


def test_diagnostic_bag_serializes_error_payload():
    stream = TokenStream.from_source("panther")
    bag = DiagnosticBag()
    diagnostic = bag.error("Expected main", stream.current, expected=(TokenKind.MAIN,), code="PARSER_EXPECTED_MAIN")
    assert bag.has_errors
    assert diagnostic.severity is DiagnosticSeverity.ERROR
    payload = bag.to_list()[0]
    assert payload["code"] == "PARSER_EXPECTED_MAIN"
    assert payload["expected"] == ["MAIN"]
    assert payload["token_kind"] == "PANTHER"


def test_parser_base_optional_rolls_back_errors_and_position():
    parser = DemoParser.from_source("print")
    result = parser.optional(parser.parse_panther_main_header)
    assert result is None
    assert parser.current.kind is TokenKind.PRINT
    assert parser.errors == []
    assert parser.diagnostics.diagnostics == []


def test_parser_base_optional_commits_successful_parse():
    parser = DemoParser.from_source("panther main { }")
    result = parser.optional(parser.parse_panther_main_header)
    assert result == "header"
    assert parser.current.kind is TokenKind.LEFT_BRACE
    assert not parser.diagnostics.has_errors


def test_expect_is_non_throwing_and_records_diagnostic():
    parser = ParserBase.from_source("panther")
    token = parser.expect(TokenKind.MAIN, "Expected main after panther")
    assert token is None
    assert parser.current.kind is TokenKind.PANTHER
    assert parser.diagnostics.has_errors
    assert parser.diagnostics.to_list()[0]["message"] == "Expected main after panther"


def test_recover_to_advances_to_requested_boundary():
    parser = ParserBase.from_source('alpha + + print("ok")')
    parser.recover_to(TokenKind.PRINT)
    assert parser.current.kind is TokenKind.PRINT


def test_parser_result_reports_success_and_failure():
    ok = ParserResult(node="program")
    assert ok.ok
    assert not ok.has_errors

    parser = ParserBase.from_source("panther")
    parser.diagnostic("expected main", expected=(TokenKind.MAIN,))
    failed = parser.result(None)
    assert not failed.ok
    assert failed.has_errors
    assert failed.to_dict()["diagnostics"][0]["expected"] == ["MAIN"]


def test_parser_base_consume_still_raises_for_strict_paths():
    parser = ParserBase.from_source("panther")
    with pytest.raises(Exception):
        parser.consume(TokenKind.MAIN)
    assert parser.diagnostics.has_errors
PY

cat > docs/compiler_runtime/r3_batch2_part3_2_2_parser_infrastructure.md <<'MD'
# R3 Batch 2 Part 3.2.2 — Parser Infrastructure

This part adds the parser infrastructure required before implementing concrete program, block, and statement parsers.

Delivered components:

- `DiagnosticSeverity`
- `ParserDiagnostic`
- `DiagnosticBag`
- `ParserContext`
- `ParserResult`
- Enhanced `ParserBase`
- Infrastructure tests
- Regression validation for the previous Token Stream segment

The design preserves strict parsing through `consume()` while adding recovery-friendly helpers through `expect()`, `optional()`, `recover_to()`, and `result()`.
MD

python - <<'PY'
import json
from pathlib import Path
manifest = {
    "part_id": "R3_BATCH2_PART3_2_2_PARSER_INFRASTRUCTURE",
    "part_name": "R3 Batch 2 Part 3.2.2 - Parser Infrastructure",
    "status": "implemented_pending_local_run",
    "requires": ["R3 Batch 2 Part 3.2.1 - Token Stream"],
    "files": [
        "compiler/parser/diagnostics.py",
        "compiler/parser/parser_context.py",
        "compiler/parser/parser_result.py",
        "compiler/parser/parser_base.py",
        "compiler/parser/__init__.py",
        "tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py",
        "docs/compiler_runtime/r3_batch2_part3_2_2_parser_infrastructure.md",
        ".panther/manifests/r3_batch2_part3_2_2_parser_infrastructure_manifest.json",
        "docs/compiler_runtime/reports/r3_batch2_part3_2_2_parser_infrastructure_report.md",
    ],
    "verification": {
        "commands": [
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q",
            "python -m pytest tests/R3_compiler_runtime -q",
        ]
    },
    "next": "R3 Batch 2 Part 3.2.3 - Program Parser",
}
Path(".panther/manifests/r3_batch2_part3_2_2_parser_infrastructure_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
PY

cat > "$REPORT_FILE" <<MD
# ${PART_NAME}

Status: implemented.

## Summary

Added reusable recursive-descent parser infrastructure on top of the completed Token Stream layer.

## Added

- Parser diagnostics and diagnostic bag
- Parser context with checkpoints and recovery
- Parser result envelope
- Enhanced parser base helpers
- Parser infrastructure tests

## Verification

Run by this bootstrap:

\`\`\`bash
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q
python -m pytest tests/R3_compiler_runtime -q
\`\`\`

## Backup

${BACKUP_DIR}

## Next

R3 Batch 2 Part 3.2.3 - Program Parser
MD

printf '\nRunning verification...\n'
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q
python -m pytest tests/R3_compiler_runtime -q

python - <<'PY'
import json
from pathlib import Path
path = Path(".panther/manifests/r3_batch2_part3_2_2_parser_infrastructure_manifest.json")
data = json.loads(path.read_text())
data["status"] = "passed"
data["local_verification"] = "passed"
path.write_text(json.dumps(data, indent=2) + "\n")
PY

printf '\n%s completed successfully.\n' "$PART_NAME"
printf 'Manifest: %s\n' "$MANIFEST_FILE"
printf 'Report: %s\n' "$REPORT_FILE"
printf 'Backup: %s\n' "$BACKUP_DIR"
printf 'Next: R3 Batch 2 Part 3.2.3 - Program Parser\n'
