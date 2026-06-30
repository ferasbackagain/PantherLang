#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Batch 2 - Parser Foundation"
echo " Part 3.1 - AST Definitions"
echo "============================================================"

ROOT="$(pwd)"
R32="$ROOT/.panther/R3_compiler_runtime"
REPORTS="$ROOT/reports/R3_compiler_runtime"
BACKUP="$ROOT/.panther/backups/R3_batch2_part3_1_ast_definitions_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R32" "$REPORTS" "$BACKUP"

fail(){ echo "[R3-B2-P3.1][ERROR] $1" >&2; exit 1; }

echo "[1/12] Pre-flight gates..."
[ -d ".git" ] || fail "Run from PantherLang project root."
[ -f "$R32/status_batch2_part2_lexer_foundation.json" ] || fail "Run R3 Batch 2 Part 2 first."
[ -d compiler/lexer ] || fail "compiler/lexer missing."

echo "[2/12] Safety backup..."
[ -d compiler/ast ] && cp -a compiler/ast "$BACKUP/compiler_ast" || true
[ -d compiler/parser ] && cp -a compiler/parser "$BACKUP/compiler_parser" || true
[ -d tests/R3_compiler_runtime ] && cp -a tests/R3_compiler_runtime "$BACKUP/tests_R3_compiler_runtime" || true
[ -d docs/compiler_runtime ] && cp -a docs/compiler_runtime "$BACKUP/docs_compiler_runtime" || true

echo "[3/12] Baseline regression..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/R3_compiler_runtime -q

echo "[4/12] Creating AST package skeleton..."
mkdir -p compiler/ast compiler/parser docs/compiler_runtime tests/R3_compiler_runtime

cat > compiler/parser/__init__.py <<'PY'
"""PantherLang parser package.

Parser implementation begins in R3 Batch 2 Part 3.2.
"""
PY

cat > compiler/ast/base.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Protocol, runtime_checkable


@dataclass(frozen=True)
class SourceLocation:
    line: int
    column: int
    index: int = 0

    def to_dict(self) -> dict[str, int]:
        return {"line": self.line, "column": self.column, "index": self.index}


@dataclass(frozen=True)
class ASTNode:
    location: SourceLocation | None = None
    metadata: dict[str, Any] = field(default_factory=dict)

    @property
    def node_type(self) -> str:
        return self.__class__.__name__

    def children(self) -> tuple["ASTNode", ...]:
        return ()

    def accept(self, visitor: "ASTVisitorProtocol") -> Any:
        method_name = f"visit_{self.node_type}"
        method = getattr(visitor, method_name, None)
        if method is None:
            method = getattr(visitor, "generic_visit")
        return method(self)


@runtime_checkable
class ASTVisitorProtocol(Protocol):
    def generic_visit(self, node: ASTNode) -> Any:
        ...
PY

echo "[5/12] Creating expressions..."
cat > compiler/ast/expressions.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass

from .base import ASTNode


@dataclass(frozen=True)
class Expression(ASTNode):
    pass


@dataclass(frozen=True)
class IdentifierExpression(Expression):
    name: str = ""


@dataclass(frozen=True)
class StringLiteral(Expression):
    value: str = ""


@dataclass(frozen=True)
class NumberLiteral(Expression):
    value: int | float = 0


@dataclass(frozen=True)
class BooleanLiteral(Expression):
    value: bool = False


@dataclass(frozen=True)
class NullLiteral(Expression):
    value: None = None


@dataclass(frozen=True)
class UnaryExpression(Expression):
    operator: str = ""
    operand: Expression | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.operand,) if self.operand is not None else ()


@dataclass(frozen=True)
class BinaryExpression(Expression):
    left: Expression | None = None
    operator: str = ""
    right: Expression | None = None

    def children(self) -> tuple[ASTNode, ...]:
        nodes = []
        if self.left is not None:
            nodes.append(self.left)
        if self.right is not None:
            nodes.append(self.right)
        return tuple(nodes)


@dataclass(frozen=True)
class CallExpression(Expression):
    callee: Expression | None = None
    arguments: tuple[Expression, ...] = ()

    def children(self) -> tuple[ASTNode, ...]:
        nodes = []
        if self.callee is not None:
            nodes.append(self.callee)
        nodes.extend(self.arguments)
        return tuple(nodes)


@dataclass(frozen=True)
class MemberExpression(Expression):
    object: Expression | None = None
    property: str = ""

    def children(self) -> tuple[ASTNode, ...]:
        return (self.object,) if self.object is not None else ()


@dataclass(frozen=True)
class ObjectLiteral(Expression):
    entries: tuple[tuple[str, Expression], ...] = ()

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(expr for _, expr in self.entries)


@dataclass(frozen=True)
class ArrayLiteral(Expression):
    items: tuple[Expression, ...] = ()

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(self.items)
PY

echo "[6/12] Creating statements/program/visitor/serializer..."
cat > compiler/ast/statements.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass

from .base import ASTNode
from .expressions import Expression


@dataclass(frozen=True)
class Statement(ASTNode):
    pass


@dataclass(frozen=True)
class BlockNode(Statement):
    statements: tuple[Statement, ...] = ()

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(self.statements)


@dataclass(frozen=True)
class PrintStatement(Statement):
    expression: Expression | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.expression,) if self.expression is not None else ()


@dataclass(frozen=True)
class ReturnStatement(Statement):
    expression: Expression | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.expression,) if self.expression is not None else ()


@dataclass(frozen=True)
class ExpressionStatement(Statement):
    expression: Expression | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.expression,) if self.expression is not None else ()


@dataclass(frozen=True)
class VariableDeclaration(Statement):
    name: str = ""
    initializer: Expression | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.initializer,) if self.initializer is not None else ()


@dataclass(frozen=True)
class AssignmentStatement(Statement):
    target: Expression | None = None
    value: Expression | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(x for x in (self.target, self.value) if x is not None)


@dataclass(frozen=True)
class IfStatement(Statement):
    condition: Expression | None = None
    then_block: BlockNode | None = None
    else_block: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(x for x in (self.condition, self.then_block, self.else_block) if x is not None)


@dataclass(frozen=True)
class WhileStatement(Statement):
    condition: Expression | None = None
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(x for x in (self.condition, self.body) if x is not None)


@dataclass(frozen=True)
class RouteStatement(Statement):
    method: str = "GET"
    path: str = "/"
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()
PY

cat > compiler/ast/program.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass

from .base import ASTNode
from .statements import BlockNode


@dataclass(frozen=True)
class ProgramNode(ASTNode):
    body: tuple[ASTNode, ...] = ()

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(self.body)


@dataclass(frozen=True)
class MainBlockNode(ASTNode):
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()


@dataclass(frozen=True)
class WebBlockNode(ASTNode):
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()


@dataclass(frozen=True)
class ApiBlockNode(ASTNode):
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()


@dataclass(frozen=True)
class AiBlockNode(ASTNode):
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()


@dataclass(frozen=True)
class TestBlockNode(ASTNode):
    name: str = ""
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()
PY

cat > compiler/ast/visitor.py <<'PY'
from __future__ import annotations

from typing import Any

from .base import ASTNode


class ASTVisitor:
    def visit(self, node: ASTNode) -> Any:
        return node.accept(self)

    def generic_visit(self, node: ASTNode) -> Any:
        return [self.visit(child) for child in node.children()]
PY

cat > compiler/ast/serializer.py <<'PY'
from __future__ import annotations

from dataclasses import fields
from enum import Enum
from typing import Any

from .base import ASTNode, SourceLocation


def ast_to_dict(value: Any) -> Any:
    if isinstance(value, ASTNode):
        data: dict[str, Any] = {"type": value.node_type}
        if value.location is not None:
            data["location"] = value.location.to_dict()
        for field in fields(value):
            if field.name in ("location", "metadata"):
                continue
            data[field.name] = ast_to_dict(getattr(value, field.name))
        if value.metadata:
            data["metadata"] = ast_to_dict(value.metadata)
        return data
    if isinstance(value, SourceLocation):
        return value.to_dict()
    if isinstance(value, tuple) or isinstance(value, list):
        return [ast_to_dict(item) for item in value]
    if isinstance(value, dict):
        return {str(k): ast_to_dict(v) for k, v in value.items()}
    if isinstance(value, Enum):
        return value.value
    return value
PY

cat > compiler/ast/__init__.py <<'PY'
from .base import ASTNode, SourceLocation
from .expressions import (
    ArrayLiteral, BinaryExpression, BooleanLiteral, CallExpression,
    Expression, IdentifierExpression, MemberExpression, NullLiteral,
    NumberLiteral, ObjectLiteral, StringLiteral, UnaryExpression,
)
from .program import AiBlockNode, ApiBlockNode, MainBlockNode, ProgramNode, TestBlockNode, WebBlockNode
from .serializer import ast_to_dict
from .statements import (
    AssignmentStatement, BlockNode, ExpressionStatement, IfStatement,
    PrintStatement, ReturnStatement, RouteStatement, Statement,
    VariableDeclaration, WhileStatement,
)
from .visitor import ASTVisitor

__all__ = [
    "ASTNode", "SourceLocation", "Expression", "IdentifierExpression",
    "StringLiteral", "NumberLiteral", "BooleanLiteral", "NullLiteral",
    "UnaryExpression", "BinaryExpression", "CallExpression", "MemberExpression",
    "ObjectLiteral", "ArrayLiteral", "Statement", "BlockNode",
    "PrintStatement", "ReturnStatement", "ExpressionStatement",
    "VariableDeclaration", "AssignmentStatement", "IfStatement",
    "WhileStatement", "RouteStatement", "ProgramNode", "MainBlockNode",
    "WebBlockNode", "ApiBlockNode", "AiBlockNode", "TestBlockNode",
    "ASTVisitor", "ast_to_dict",
]
PY

echo "[7/12] Creating tests..."
cat > tests/R3_compiler_runtime/test_r3_batch2_part3_1_ast_definitions.py <<'PY'
from compiler.ast import (
    ASTVisitor, BinaryExpression, BlockNode, MainBlockNode,
    NumberLiteral, PrintStatement, ProgramNode, SourceLocation,
    StringLiteral, ast_to_dict,
)


def test_create_hello_world_ast():
    expr = StringLiteral(value="Hello World")
    stmt = PrintStatement(expression=expr)
    block = BlockNode(statements=(stmt,))
    main = MainBlockNode(body=block)
    program = ProgramNode(body=(main,))
    assert program.children() == (main,)
    assert main.children() == (block,)
    assert block.children() == (stmt,)
    assert stmt.children() == (expr,)


def test_source_location_serializes():
    loc = SourceLocation(line=2, column=5, index=12)
    node = StringLiteral(value="x", location=loc)
    data = ast_to_dict(node)
    assert data["type"] == "StringLiteral"
    assert data["location"]["line"] == 2
    assert data["value"] == "x"


def test_binary_expression_children_and_serialization():
    expr = BinaryExpression(left=NumberLiteral(value=1), operator="+", right=NumberLiteral(value=2))
    assert len(expr.children()) == 2
    data = ast_to_dict(expr)
    assert data["type"] == "BinaryExpression"
    assert data["operator"] == "+"
    assert data["left"]["value"] == 1
    assert data["right"]["value"] == 2


def test_visitor_generic_traversal():
    class CountingVisitor(ASTVisitor):
        def __init__(self):
            self.count = 0
        def generic_visit(self, node):
            self.count += 1
            for child in node.children():
                self.visit(child)
            return self.count

    program = ProgramNode(body=(MainBlockNode(body=BlockNode(statements=(PrintStatement(expression=StringLiteral(value="Hello")),))),))
    visitor = CountingVisitor()
    visitor.visit(program)
    assert visitor.count == 5


def test_ast_nodes_are_comparable():
    assert StringLiteral(value="same") == StringLiteral(value="same")
    assert StringLiteral(value="same") != StringLiteral(value="different")
PY

echo "[8/12] Documentation..."
cat > docs/compiler_runtime/AST_DEFINITIONS.md <<'EOF'
# PantherLang AST Definitions

R3 Batch 2 Part 3.1 defines the official PantherLang AST model.

## Core Nodes

- ProgramNode
- MainBlockNode
- WebBlockNode
- ApiBlockNode
- AiBlockNode
- TestBlockNode
- BlockNode

## Statements

- PrintStatement
- ReturnStatement
- ExpressionStatement
- VariableDeclaration
- AssignmentStatement
- IfStatement
- WhileStatement
- RouteStatement

## Expressions

- IdentifierExpression
- StringLiteral
- NumberLiteral
- BooleanLiteral
- NullLiteral
- UnaryExpression
- BinaryExpression
- CallExpression
- MemberExpression
- ObjectLiteral
- ArrayLiteral

Parser implementation begins in R3 Batch 2 Part 3.2.
EOF

echo "[9/12] Validation..."
python3 -m py_compile \
  compiler/ast/base.py compiler/ast/expressions.py compiler/ast/statements.py \
  compiler/ast/program.py compiler/ast/visitor.py compiler/ast/serializer.py \
  compiler/ast/__init__.py compiler/parser/__init__.py \
  tests/R3_compiler_runtime/test_r3_batch2_part3_1_ast_definitions.py

python3 -m pytest tests/R3_compiler_runtime -q

echo "[10/12] Writing manifest..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
r32 = root / ".panther/R3_compiler_runtime"
files = [
    "compiler/ast/base.py", "compiler/ast/expressions.py",
    "compiler/ast/statements.py", "compiler/ast/program.py",
    "compiler/ast/visitor.py", "compiler/ast/serializer.py",
    "compiler/ast/__init__.py", "compiler/parser/__init__.py",
    "docs/compiler_runtime/AST_DEFINITIONS.md",
    "tests/R3_compiler_runtime/test_r3_batch2_part3_1_ast_definitions.py",
]
manifest = {
    "ok": True,
    "phase": "R3",
    "batch": "2",
    "part": "3.1",
    "name": "AST Definitions",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "runtime_modified": True,
    "features": ["base_ast_node", "source_location", "expressions", "statements", "program_nodes", "visitor_pattern", "serializer", "ast_tests"],
    "files": [{"path": f, "sha256": hashlib.sha256((root / f).read_bytes()).hexdigest(), "size": (root / f).stat().st_size} for f in files if (root / f).exists()],
    "next": "R3 Batch 2 Part 3.2 - Recursive Descent Parser Core"
}
(r32 / "batch2_part3_1_ast_definitions_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ manifest written")
PY

echo "[11/12] Writing report/status..."
cat > "$REPORTS/R3_BATCH2_PART3_1_AST_DEFINITIONS.md" <<'EOF'
# R3 Batch 2 Part 3.1 - AST Definitions

## Status

PASSED

## Added

- AST base classes
- SourceLocation
- Expression nodes
- Statement nodes
- Program nodes
- Visitor pattern
- AST serializer
- AST tests
- AST documentation

## Next

R3 Batch 2 Part 3.2 - Recursive Descent Parser Core.
EOF

cat > "$R32/status_batch2_part3_1_ast_definitions.json" <<'EOF'
{
  "ok": true,
  "phase": "R3",
  "batch": "2",
  "part": "3.1",
  "status": "PASSED",
  "name": "AST Definitions",
  "runtime_modified": true,
  "next": "R3 Batch 2 Part 3.2 - Recursive Descent Parser Core"
}
EOF

echo "[12/12] Done."
echo "============================================================"
echo "✅ R3 Batch 2 Part 3.1 COMPLETE"
echo "✅ AST Definitions READY"
echo "Next: R3 Batch 2 Part 3.2 - Recursive Descent Parser Core"
echo "============================================================"
