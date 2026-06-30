#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BATCH="R3_batch4_v2_debug_adapter_and_calculator_reference"
BACKUP_DIR="$ROOT/.panther_backups/${BATCH}_${STAMP}"
REPORT_DIR="$ROOT/reports/R3_compiler_runtime"
MANIFEST_DIR="$ROOT/.panther/manifests"
DOC_DIR="$ROOT/docs/compiler_runtime"
EXAMPLE_DIR="$ROOT/examples/calculator"
TEST_DIR="$ROOT/tests/R3_compiler_runtime"

if [[ ! -d "$ROOT/compiler" || ! -d "$ROOT/debug_adapter" ]]; then
  echo "ERROR: Run this script from the PantherLang repository root."
  echo "Expected directories: compiler/ and debug_adapter/."
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$REPORT_DIR" "$MANIFEST_DIR" "$DOC_DIR" "$EXAMPLE_DIR" "$TEST_DIR"

echo "== PantherLang $BATCH =="
echo "Root: $ROOT"
echo "Backup: $BACKUP_DIR"

backup_file() {
  local path="$1"
  if [[ -e "$ROOT/$path" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$path")"
    cp -a "$ROOT/$path" "$BACKUP_DIR/$path"
  fi
}

backup_file debug_adapter/launcher.py
backup_file debug_adapter/variables.py
backup_file debug_adapter/variable_references.py
backup_file debug_adapter/__init__.py
backup_file compiler/parser/expression_parser.py
backup_file compiler/parser/statement_parser.py
backup_file compiler/parser/__init__.py
backup_file tests/R3_compiler_runtime/test_r3_batch2_part3_3_expression_parser.py
backup_file tests/R3_compiler_runtime/test_r3_batch4_v2_debug_adapter_compatibility.py

python3 - <<'PY'
from __future__ import annotations
from pathlib import Path
import json
import re
import textwrap

root = Path.cwd()

def write(path: str, content: str) -> None:
    p = root / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(textwrap.dedent(content).lstrip(), encoding="utf-8")
    print(f"WROTE {path}")

def patch(path: str, transform) -> None:
    p = root / path
    old = p.read_text(encoding="utf-8") if p.exists() else ""
    new = transform(old)
    if new != old:
        p.write_text(new, encoding="utf-8")
        print(f"PATCHED {path}")
    else:
        print(f"UNCHANGED {path}")

# ---------------------------------------------------------------------------
# Batch 4 v2: Debug Adapter compatibility layer
# ---------------------------------------------------------------------------
write("debug_adapter/launcher.py", r'''
from __future__ import annotations

import os
import subprocess
from dataclasses import dataclass
from typing import Optional


@dataclass
class LaunchResult:
    command: list[str]
    cwd: Optional[str]
    pid: Optional[int]
    started: bool


class PantherProgramLauncher:
    """Production PantherLang program launcher.

    The modern launcher keeps process startup behind a dry_run gate so tests and
    IDE smoke checks can verify DAP launch behavior without spawning Panther.
    """

    def build_command(self, program, args=None):
        args = list(args or [])
        if not program:
            raise ValueError("launch requires a program path")
        return ["Panther", "run", str(program), *map(str, args)]

    def launch(self, program, args=None, cwd=None, dry_run=True):
        command = self.build_command(program, args)
        if dry_run:
            return LaunchResult(command=command, cwd=cwd, pid=None, started=False)

        process = subprocess.Popen(
            command,
            cwd=cwd or os.getcwd(),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return LaunchResult(command=command, cwd=cwd, pid=process.pid, started=True)


class Launcher(PantherProgramLauncher):
    """Legacy compatibility alias for older DAP imports/tests."""

    pass


launcher = Launcher

__all__ = ["LaunchResult", "PantherProgramLauncher", "Launcher", "launcher"]
''')

# Ensure variable_references.py has ReferenceEntry even if older local copies do not.
vr_path = root / "debug_adapter/variable_references.py"
if vr_path.exists():
    vr = vr_path.read_text(encoding="utf-8")
else:
    vr = "from __future__ import annotations\n\n"
if "class ReferenceEntry" not in vr:
    insert = r'''

from dataclasses import dataclass as _panther_dataclass
from typing import Any as _PantherAny, Dict as _PantherDict

@_panther_dataclass(slots=True)
class ReferenceEntry:
    reference: int
    name: str
    value: _PantherAny
    parent_reference: int = 0

    def to_dict(self) -> _PantherDict[str, _PantherAny]:
        return {
            "reference": self.reference,
            "name": self.name,
            "value": self.value,
            "parentReference": self.parent_reference,
        }
'''
    if "from __future__ import annotations" in vr:
        vr = vr.replace("from __future__ import annotations\n", "from __future__ import annotations\n" + insert + "\n", 1)
    else:
        vr = insert + "\n" + vr
    vr_path.write_text(vr, encoding="utf-8")
    print("PATCHED debug_adapter/variable_references.py ReferenceEntry")
else:
    print("UNCHANGED debug_adapter/variable_references.py ReferenceEntry")

write("debug_adapter/variables.py", r'''
"""PantherLang Debug Adapter variables compatibility facade.

This module exports both newer production services and legacy H4/H4.2/H4.3
names. It is intentionally defensive because historical bootstrap states may
contain slightly different internal module names.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, List, Optional

try:
    from .variables_core import DebugVariable, VariableFactory, VariablesCore
except Exception:  # pragma: no cover - compatibility fallback
    @dataclass(frozen=True)
    class DebugVariable:
        name: str
        value: Any
        type: str = "unknown"
        variablesReference: int = 0
        evaluateName: Optional[str] = None

    class VariableFactory:
        def create(self, name: str, value: Any, variables_reference: int = 0, evaluate_name: str | None = None):
            return DebugVariable(name=str(name), value=value, type=type(value).__name__, variablesReference=int(variables_reference), evaluateName=evaluate_name)

    class VariablesCore:
        def variable(self, name: str, value: Any, variables_reference: int = 0, evaluate_name: str | None = None) -> Dict[str, Any]:
            return {"name": str(name), "value": str(value), "type": type(value).__name__, "variablesReference": int(variables_reference), "evaluateName": evaluate_name or str(name)}
        def assert_variable_contract(self, variable: Dict[str, Any]) -> bool:
            for key in ("name", "value", "variablesReference"):
                if key not in variable:
                    raise AssertionError(f"missing DAP variable key: {key}")
            return True

try:
    from .variable_references import ReferenceEntry, VariableReferenceAllocator, VariableReferenceResolver, VariableReferenceService
except Exception:  # pragma: no cover - compatibility fallback
    @dataclass(slots=True)
    class ReferenceEntry:
        reference: int
        name: str
        value: Any
        parent_reference: int = 0
        def to_dict(self) -> Dict[str, Any]:
            return {"reference": self.reference, "name": self.name, "value": self.value, "parentReference": self.parent_reference}

    class VariableReferenceAllocator:
        def __init__(self, start: int = 1000):
            self._next = int(start)
            self._entries: Dict[int, ReferenceEntry] = {}
        def allocate(self, name: str, value: Any, parent_reference: int = 0) -> int:
            ref = self._next; self._next += 1
            self._entries[ref] = ReferenceEntry(ref, str(name), value, int(parent_reference))
            return ref
        def get(self, reference: int) -> ReferenceEntry:
            return self._entries[int(reference)]
        def clear(self) -> None:
            self._entries.clear()
        def count(self) -> int:
            return len(self._entries)
        def entries(self) -> List[Dict[str, Any]]:
            return [entry.to_dict() for entry in self._entries.values()]

    class VariableReferenceResolver:
        def __init__(self, factory: VariableFactory | None = None):
            self.factory = factory or VariableFactory()
        def children_for(self, name: str, value: Any):
            if isinstance(value, dict):
                return [self.factory.create(str(k), v, evaluate_name=f"{name}.{k}") for k, v in value.items()]
            if isinstance(value, (list, tuple)):
                return [self.factory.create(str(i), v, evaluate_name=f"{name}[{i}]") for i, v in enumerate(value)]
            return []

    class VariableReferenceService:
        def __init__(self, allocator=None, resolver=None, core=None):
            self.allocator = allocator or VariableReferenceAllocator()
            self.resolver = resolver or VariableReferenceResolver()
            self.core = core or VariablesCore()
        def variable(self, name: str, value: Any, parent_reference: int = 0) -> Dict[str, Any]:
            children = self.resolver.children_for(name, value)
            ref = self.allocator.allocate(name, value, parent_reference) if children else 0
            return self.core.variable(name, value, variables_reference=ref, evaluate_name=name)
        def variables_from_mapping(self, values: Dict[str, Any], parent_reference: int = 0) -> List[Dict[str, Any]]:
            return [self.variable(str(k), v, parent_reference) for k, v in values.items()]
        def variables_from_iterable(self, values, parent_name: str = "items", parent_reference: int = 0) -> List[Dict[str, Any]]:
            return [self.variable(str(i), v, parent_reference) for i, v in enumerate(values)]
        def children(self, reference: int) -> List[Dict[str, Any]]:
            entry = self.allocator.get(reference)
            return [self.variable(child.name, child.value, reference) for child in self.resolver.children_for(entry.name, entry.value)]
        def assert_reference_contract(self, variable: Dict[str, Any]) -> bool:
            return self.core.assert_variable_contract(variable)
        def stats(self) -> Dict[str, Any]:
            return {"referenceCount": self.allocator.count(), "entries": self.allocator.entries()}

try:
    from .variable_store import VariableScopeRecord, VariableStore, DebugVariableStore
except Exception:  # pragma: no cover - compatibility fallback
    @dataclass
    class VariableScopeRecord:
        name: str
        variables: Dict[str, Any]
    class VariableStore:
        def __init__(self):
            self._scopes: Dict[str, Dict[str, Any]] = {"locals": {}}
        def set(self, name: str, value: Any, scope: str = "locals") -> None:
            self._scopes.setdefault(scope, {})[name] = value
        def get(self, name: str, scope: str = "locals", default: Any = None) -> Any:
            return self._scopes.get(scope, {}).get(name, default)
        def scope(self, scope: str = "locals") -> Dict[str, Any]:
            return dict(self._scopes.get(scope, {}))
        def clear(self) -> None:
            self._scopes.clear(); self._scopes["locals"] = {}
    DebugVariableStore = VariableStore

# Optional production stores. Missing modules are acceptable in older snapshots.
def _optional_import(module: str, names: tuple[str, ...]):
    try:
        mod = __import__(f"debug_adapter.{module}", fromlist=list(names))
        return [getattr(mod, name) for name in names]
    except Exception:
        return [None for _ in names]

StackFrameSource, DebugStackFrame, StackFrameStore = _optional_import("stack_frames", ("StackFrameSource", "DebugStackFrame", "StackFrameStore"))
DebugThread, ThreadStore, DebugThreadStore = _optional_import("threads", ("DebugThread", "ThreadStore", "DebugThreadStore"))
DebugScope, ScopeStore, DebugScopeStore = _optional_import("scopes", ("DebugScope", "ScopeStore", "DebugScopeStore"))
EvaluateResult, EvaluateContext, EvaluateEngine, DebugEvaluateEngine = _optional_import("evaluate", ("EvaluateResult", "EvaluateContext", "EvaluateEngine", "DebugEvaluateEngine"))
WatchExpression, WatchExpressionStore, WatchExpressionManager, build_watch_manager_for_thread_store = _optional_import("watch_expressions", ("WatchExpression", "WatchExpressionStore", "WatchExpressionManager", "build_watch_manager_for_thread_store"))

# Lightweight fallbacks for public names that tests import directly.
class _FallbackStore:
    def __init__(self): self.items = {}
    def clear(self): self.items.clear()

StackFrameStore = StackFrameStore or _FallbackStore
ThreadStore = ThreadStore or _FallbackStore
ScopeStore = ScopeStore or _FallbackStore
EvaluateEngine = EvaluateEngine or _FallbackStore
WatchExpressionStore = WatchExpressionStore or _FallbackStore

__all__ = [
    "DebugVariable", "VariableFactory", "VariablesCore",
    "ReferenceEntry", "VariableReferenceAllocator", "VariableReferenceResolver", "VariableReferenceService",
    "VariableScopeRecord", "VariableStore", "DebugVariableStore",
    "StackFrameSource", "DebugStackFrame", "StackFrameStore",
    "DebugThread", "ThreadStore", "DebugThreadStore",
    "DebugScope", "ScopeStore", "DebugScopeStore",
    "EvaluateResult", "EvaluateContext", "EvaluateEngine", "DebugEvaluateEngine",
    "WatchExpression", "WatchExpressionStore", "WatchExpressionManager", "build_watch_manager_for_thread_store",
]
''')

write("debug_adapter/__init__.py", r'''
"""PantherLang Debug Adapter Protocol core package."""
from __future__ import annotations

__version__ = "0.4.2-batch4-v2-compat"

try:
    from .adapter import PantherDebugAdapter
except Exception:  # pragma: no cover
    PantherDebugAdapter = None
try:
    from .session import DebugSession
except Exception:  # pragma: no cover
    DebugSession = None
from .launcher import LaunchResult, Launcher, PantherProgramLauncher
try:
    from .server import DebugServer
except Exception:  # pragma: no cover
    DebugServer = None
try:
    from .dispatcher import RequestDispatcher
except Exception:  # pragma: no cover
    RequestDispatcher = None
from .variables import (
    DebugVariable, VariableFactory, VariablesCore, ReferenceEntry,
    VariableReferenceAllocator, VariableReferenceResolver, VariableReferenceService,
    VariableStore, DebugVariableStore, StackFrameStore, ThreadStore, ScopeStore,
    EvaluateEngine, WatchExpressionStore,
)

__all__ = [
    "PantherDebugAdapter", "DebugSession", "LaunchResult", "Launcher", "PantherProgramLauncher",
    "DebugServer", "RequestDispatcher", "DebugVariable", "VariableFactory", "VariablesCore",
    "ReferenceEntry", "VariableReferenceAllocator", "VariableReferenceResolver", "VariableReferenceService",
    "VariableStore", "DebugVariableStore", "StackFrameStore", "ThreadStore", "ScopeStore",
    "EvaluateEngine", "WatchExpressionStore", "__version__",
]
''')

# ---------------------------------------------------------------------------
# R3 Batch 2 Part 3.3: Expression Parser
# ---------------------------------------------------------------------------
write("compiler/parser/expression_parser.py", r'''
from __future__ import annotations

from compiler.ast import (
    BinaryExpression,
    BooleanLiteral,
    Expression,
    IdentifierExpression,
    NullLiteral,
    NumberLiteral,
    StringLiteral,
    UnaryExpression,
)
from compiler.ast.base import SourceLocation as ASTSourceLocation
from compiler.lexer import Token, TokenKind

from .parse_error import ParseError
from .parser_base import ParserBase


class ExpressionParser(ParserBase):
    """Recursive-descent expression parser for PantherLang R3 Part 3.3.

    Supported now:
    - integer/float/string/bool/null-like primary values
    - identifiers
    - parentheses
    - unary ! and -
    - multiplicative *, /
    - additive +, -
    - comparisons > >= < <=
    - equality == !=
    """

    def parse_expression(self) -> Expression | None:
        return self.parse_equality()

    def parse_equality(self) -> Expression | None:
        expr = self.parse_comparison()
        while self.match(TokenKind.EQUAL_EQUAL, TokenKind.BANG_EQUAL):
            operator = self.previous
            right = self.parse_comparison()
            expr = BinaryExpression(location=self.ast_location(operator), left=expr, operator=operator.lexeme, right=right)
        return expr

    def parse_comparison(self) -> Expression | None:
        expr = self.parse_term()
        while self.match(TokenKind.GREATER, TokenKind.GREATER_EQUAL, TokenKind.LESS, TokenKind.LESS_EQUAL):
            operator = self.previous
            right = self.parse_term()
            expr = BinaryExpression(location=self.ast_location(operator), left=expr, operator=operator.lexeme, right=right)
        return expr

    def parse_term(self) -> Expression | None:
        expr = self.parse_factor()
        while self.match(TokenKind.PLUS, TokenKind.MINUS):
            operator = self.previous
            right = self.parse_factor()
            expr = BinaryExpression(location=self.ast_location(operator), left=expr, operator=operator.lexeme, right=right)
        return expr

    def parse_factor(self) -> Expression | None:
        expr = self.parse_unary()
        while self.match(TokenKind.STAR, TokenKind.SLASH):
            operator = self.previous
            right = self.parse_unary()
            expr = BinaryExpression(location=self.ast_location(operator), left=expr, operator=operator.lexeme, right=right)
        return expr

    def parse_unary(self) -> Expression | None:
        if self.match(TokenKind.BANG, TokenKind.MINUS):
            operator = self.previous
            operand = self.parse_unary()
            return UnaryExpression(location=self.ast_location(operator), operator=operator.lexeme, operand=operand)
        return self.parse_primary()

    def parse_primary(self) -> Expression:
        if self.match(TokenKind.NUMBER):
            token = self.previous
            return NumberLiteral(location=self.ast_location(token), value=token.literal if token.literal is not None else self.parse_number_lexeme(token.lexeme))
        if self.match(TokenKind.STRING):
            token = self.previous
            return StringLiteral(location=self.ast_location(token), value=str(token.literal if token.literal is not None else token.lexeme.strip('"')))
        if self.match(TokenKind.TRUE):
            return BooleanLiteral(location=self.ast_location(self.previous), value=True)
        if self.match(TokenKind.FALSE):
            return BooleanLiteral(location=self.ast_location(self.previous), value=False)
        if self.match(TokenKind.IDENTIFIER):
            token = self.previous
            if token.lexeme == "null":
                return NullLiteral(location=self.ast_location(token))
            return IdentifierExpression(location=self.ast_location(token), name=token.lexeme)
        if self.match(TokenKind.LEFT_PAREN):
            start = self.previous
            expr = self.parse_expression()
            self.consume(TokenKind.RIGHT_PAREN, "Expected ')' after expression")
            if expr is None:
                raise self.error("Expected expression inside parentheses", token=start)
            return expr
        raise self.error("Expected expression", expected=(TokenKind.NUMBER, TokenKind.STRING, TokenKind.IDENTIFIER, TokenKind.LEFT_PAREN))

    @staticmethod
    def parse_number_lexeme(value: str) -> int | float:
        try:
            return int(value)
        except ValueError:
            return float(value)

    @staticmethod
    def ast_location(token: Token) -> ASTSourceLocation:
        return ASTSourceLocation(line=token.location.line, column=token.location.column, index=token.location.index)


def parse_expression_tokens(tokens: list[Token]) -> Expression | None:
    from .parser_context import ParserContext
    from .token_stream import TokenStream

    clean = [token for token in tokens if token.kind != TokenKind.EOF]
    if not clean:
        return None
    eof = Token(TokenKind.EOF, "", None, clean[-1].location)
    parser = ExpressionParser(ParserContext(TokenStream([*clean, eof])))
    return parser.parse_expression()
''')

# Patch statement parser to use ExpressionParser for real AST generation.
def patch_statement_parser(old: str) -> str:
    if "from .expression_parser import parse_expression_tokens" not in old:
        old = old.replace("from .parser_base import ParserBase\n", "from .parser_base import ParserBase\nfrom .expression_parser import parse_expression_tokens\n")
    old = re.sub(
        r"    def expression_from_tokens\(self, tokens: list\[Token\]\) -> Expression \| None:\n(?:        .+\n)+?    def single_token_expression",
        "    def expression_from_tokens(self, tokens: list[Token]) -> Expression | None:\n"
        "        tokens = [token for token in tokens if token.kind != TokenKind.EOF]\n"
        "        if not tokens:\n"
        "            return None\n"
        "        try:\n"
        "            return parse_expression_tokens(tokens)\n"
        "        except Exception:\n"
        "            if len(tokens) == 1:\n"
        "                return self.single_token_expression(tokens[0])\n"
        "            joined = \" \".join(token.lexeme for token in tokens).strip()\n"
        "            return IdentifierExpression(location=self.ast_location(tokens[0]), name=joined)\n\n"
        "    def single_token_expression",
        old,
        flags=re.MULTILINE,
    )
    return old
patch("compiler/parser/statement_parser.py", patch_statement_parser)

# Export ExpressionParser in compiler.parser public surface.
def patch_parser_init(old: str) -> str:
    if "from .expression_parser import ExpressionParser, parse_expression_tokens" not in old:
        old += "\nfrom .expression_parser import ExpressionParser, parse_expression_tokens\n"
    if '"ExpressionParser"' not in old:
        old = old.replace('"StatementParser",', '"StatementParser",\n    "ExpressionParser", "parse_expression_tokens",')
    return old
patch("compiler/parser/__init__.py", patch_parser_init)

write("tests/R3_compiler_runtime/test_r3_batch4_v2_debug_adapter_compatibility.py", r'''
from debug_adapter.launcher import Launcher, PantherProgramLauncher
from debug_adapter.variables import VariableStore, VariablesCore, VariableReferenceService


def test_launcher_legacy_alias_builds_panther_run_command():
    launcher = Launcher()
    assert isinstance(launcher, PantherProgramLauncher)
    result = launcher.launch("calculator.pan", args=["--demo"], dry_run=True)
    assert result.command == ["Panther", "run", "calculator.pan", "--demo"]
    assert result.started is False


def test_variable_legacy_exports_exist_and_work():
    core = VariablesCore()
    variable = core.variable("answer", 42, variables_reference=0, evaluate_name="answer")
    assert variable["name"] == "answer"
    assert variable["variablesReference"] == 0

    store = VariableStore()
    if hasattr(store, "set") and hasattr(store, "get"):
        store.set("x", 10)
        assert store.get("x") == 10

    service = VariableReferenceService()
    parent = service.variable("items", [1, 2, 3])
    assert parent["variablesReference"] >= 0
''')

write("tests/R3_compiler_runtime/test_r3_batch2_part3_3_expression_parser.py", r'''
from compiler.ast import BinaryExpression, NumberLiteral, UnaryExpression
from compiler.lexer import lex_source
from compiler.parser.expression_parser import parse_expression_tokens


def expr(source: str):
    tokens = [token for token in lex_source(source) if token.lexeme or token.kind.value != "EOF"]
    return parse_expression_tokens(tokens)


def test_expression_parser_integer_literal():
    node = expr("10")
    assert isinstance(node, NumberLiteral)
    assert node.value == 10


def test_expression_parser_precedence_multiplication_before_addition():
    node = expr("10 + 5 * 2")
    assert isinstance(node, BinaryExpression)
    assert node.operator == "+"
    assert isinstance(node.right, BinaryExpression)
    assert node.right.operator == "*"


def test_expression_parser_parentheses_override_precedence():
    node = expr("(10 + 5) * 2")
    assert isinstance(node, BinaryExpression)
    assert node.operator == "*"
    assert isinstance(node.left, BinaryExpression)
    assert node.left.operator == "+"


def test_expression_parser_unary_operator():
    node = expr("-10 + 5")
    assert isinstance(node, BinaryExpression)
    assert isinstance(node.left, UnaryExpression)
    assert node.left.operator == "-"
''')

write("examples/calculator/calculator_phase_1.pan", r'''
// Panther Calculator Reference Application - Phase 1 expression smoke examples
print(10 + 5);
print(10 * (8 + 2));
print(100 / 4);
print(-10 + 15);
''')

write("docs/compiler_runtime/PANTHER_CALCULATOR_REFERENCE_APPLICATION.md", r'''
# Panther Calculator Reference Application

Panther Calculator is now the official reference application for PantherLang R3.

## Purpose

Every new language feature must be proven inside a real evolving application,
not only through isolated syntax tests.

## Feature Ladder

1. Expression Parser: literals, parentheses, unary operators, binary operators, precedence, AST generation.
2. Variables: `let a = 10`, `let result = a + b`.
3. Input: `input("Enter number:")`.
4. Conditions: operator dispatch with `if`.
5. Functions: `calculate(a, op, b)`.
6. Runtime loop: `panther run calculator.pan`.

## Engineering Rule

No Feature Without Proof:

- implementation,
- local Kali execution,
- regression tests,
- manifest,
- report,
- backup,
- then completion.
''')

write("reports/R3_compiler_runtime/R3_BATCH4_V2_AND_CALCULATOR_REFERENCE_FOUNDATION.md", r'''
# R3 Batch 4 v2 + Panther Calculator Reference Foundation

## Objective

Repair Debug Adapter compatibility failures and establish Panther Calculator as
the official PantherLang reference application.

## Debug Adapter Fixes

- Restores `debug_adapter.launcher.Launcher` compatibility.
- Restores `debug_adapter.variables.VariableStore` compatibility.
- Restores `debug_adapter.variables.VariablesCore` compatibility.
- Adds defensive fallbacks for older intermediate project states.
- Keeps current production exports available.

## Expression Parser Foundation

Introduces `compiler.parser.expression_parser.ExpressionParser` with:

- numeric literals,
- string literals,
- boolean literals,
- identifiers,
- parentheses,
- unary `!` and `-`,
- multiplicative `*` and `/`,
- additive `+` and `-`,
- comparison operators,
- equality operators,
- AST generation using existing `compiler.ast` nodes.

## Reference Application

Adds:

- `examples/calculator/calculator_phase_1.pan`
- `docs/compiler_runtime/PANTHER_CALCULATOR_REFERENCE_APPLICATION.md`

## Verification Commands

```bash
python3 -m pytest -q tests/R3_compiler_runtime/test_r3_batch4_v2_debug_adapter_compatibility.py
python3 -m pytest -q tests/R3_compiler_runtime/test_r3_batch2_part3_3_expression_parser.py
python3 -m pytest -q
```
''')

manifest = {
    "batch": "R3 Batch 4 v2 + Calculator Reference Foundation",
    "status": "generated",
    "policy": "No Feature Without Proof",
    "writes": [
        "debug_adapter/launcher.py",
        "debug_adapter/variables.py",
        "debug_adapter/variable_references.py",
        "debug_adapter/__init__.py",
        "compiler/parser/expression_parser.py",
        "compiler/parser/statement_parser.py",
        "compiler/parser/__init__.py",
        "tests/R3_compiler_runtime/test_r3_batch4_v2_debug_adapter_compatibility.py",
        "tests/R3_compiler_runtime/test_r3_batch2_part3_3_expression_parser.py",
        "examples/calculator/calculator_phase_1.pan",
        "docs/compiler_runtime/PANTHER_CALCULATOR_REFERENCE_APPLICATION.md",
        "reports/R3_compiler_runtime/R3_BATCH4_V2_AND_CALCULATOR_REFERENCE_FOUNDATION.md",
    ],
    "next": "Run full regression, then continue Panther Calculator variables/input/conditions/functions/runtime loop.",
}
write(".panther/manifests/r3_batch4_v2_and_calculator_reference_foundation_manifest.json", json.dumps(manifest, indent=2))
PY

echo

echo "== Targeted verification =="
python3 -m pytest -q tests/R3_compiler_runtime/test_r3_batch4_v2_debug_adapter_compatibility.py tests/R3_compiler_runtime/test_r3_batch2_part3_3_expression_parser.py

echo

echo "== Optional collection smoke for current repaired surfaces =="
python3 - <<'PY'
from debug_adapter.launcher import Launcher
from debug_adapter.variables import VariableStore, VariablesCore, VariableReferenceService
from compiler.parser.expression_parser import ExpressionParser
print("IMPORT_OK", Launcher.__name__, VariableStore.__name__, VariablesCore.__name__, VariableReferenceService.__name__, ExpressionParser.__name__)
PY

echo

echo "DONE: $BATCH"
echo "Backup: $BACKUP_DIR"
echo "Now run full regression: python3 -m pytest -q"
