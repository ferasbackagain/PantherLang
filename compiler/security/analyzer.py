from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any

from compiler.ast import (
    AssignmentStatement,
    BinaryExpression,
    BlockNode,
    CallExpression,
    Expression,
    ExpressionStatement,
    ForStatement,
    FunctionDeclaration,
    IdentifierExpression,
    IfStatement,
    ImportStatement,
    LoopStatement,
    MemberExpression,
    PrintStatement,
    ReturnStatement,
    StringLiteral,
    VariableDeclaration,
    WhileStatement,
)
from compiler.ast.base import ASTNode
from compiler.ast.program import ProgramNode
from compiler.semantic.diagnostics import SemanticError, SemanticWarning


_SECRET_PATTERNS: list[re.Pattern] = [
    re.compile(r"(?i)(?:api[_-]?key|secret|password|token|credential)\s*[=:]\s*['\"][^'\"]+['\"]"),
    re.compile(r"(?i)sk-[a-zA-Z0-9]{20,}"),
    re.compile(r"(?i)pk-[a-zA-Z0-9]{20,}"),
]

_DANGEROUS_API_NAMES: set[str] = {
    "exec", "eval", "compile", "__import__", "open", "system", "popen",
    "subprocess", "run_shell", "shell_exec", "unsafe_eval",
}

_DANGEROUS_KEYWORDS: set[str] = {
    "rm -rf", "sudo", "chmod 777", "> /dev/null", "2>&1",
}


@dataclass
class SecurityDiagnostic:
    message: str = ""
    code: str = ""
    severity: str = "warning"
    location: Any = None

    def __str__(self) -> str:
        prefix = f"[{self.code}]" if self.code else ""
        loc = f" at {self.location}" if self.location is not None else ""
        return f"{prefix}{loc}: {self.message}"


class SecurityAnalyzer:
    def __init__(self) -> None:
        self.diagnostics: list[SecurityDiagnostic] = []

    def analyze(self, node: ASTNode) -> list[SecurityDiagnostic]:
        if isinstance(node, ProgramNode):
            for item in node.body:
                self._visit_node(item)
        elif isinstance(node, BlockNode):
            for s in node.statements:
                self._visit_statement(s)
        else:
            self._visit_statement(node)
        return list(self.diagnostics)

    def _visit_node(self, item: Any) -> None:
        if isinstance(item, BlockNode):
            for s in item.statements:
                self._visit_statement(s)
        elif isinstance(item, FunctionDeclaration) and item.body:
            self._visit_statement(item)
        elif hasattr(item, "body") and hasattr(item.body, "statements"):
            for s in item.body.statements:
                self._visit_statement(s)
        else:
            self._visit_statement(item)

    def _visit_statement(self, stmt: Any) -> None:
        if isinstance(stmt, VariableDeclaration):
            self._check_variable_declaration(stmt)
        elif isinstance(stmt, FunctionDeclaration):
            self._check_function_declaration(stmt)
            if stmt.body:
                for s in stmt.body.statements:
                    self._visit_statement(s)
            return
        elif isinstance(stmt, ExpressionStatement):
            self._visit_expression(stmt.expression)
        elif isinstance(stmt, PrintStatement):
            self._visit_expression(stmt.expression)
        elif isinstance(stmt, ReturnStatement):
            self._visit_expression(stmt.expression)
        elif isinstance(stmt, AssignmentStatement):
            self._visit_expression(stmt.value)
            self._check_assignment(stmt)
        elif isinstance(stmt, IfStatement):
            self._visit_expression(stmt.condition)
        elif isinstance(stmt, BlockNode):
            for s in stmt.statements:
                self._visit_statement(s)
            return

        if hasattr(stmt, "body"):
            body = stmt.body
            if body is not None and hasattr(body, "statements"):
                for s in body.statements:
                    self._visit_statement(s)

        if hasattr(stmt, "then_block") and stmt.then_block:
            for s in stmt.then_block.statements:
                self._visit_statement(s)
        if hasattr(stmt, "else_block") and stmt.else_block:
            for s in stmt.else_block.statements:
                self._visit_statement(s)
        if hasattr(stmt, "elif_branches"):
            for branch in stmt.elif_branches:
                if branch.body:
                    for s in branch.body.statements:
                        self._visit_statement(s)

    def _visit_expression(self, expr: Any) -> None:
        if expr is None:
            return
        if isinstance(expr, CallExpression):
            self._check_call_expression(expr)
            self._visit_expression(expr.callee)
            for arg in expr.arguments:
                self._visit_expression(arg)
        elif isinstance(expr, StringLiteral):
            self._check_string_literal(expr)
        elif isinstance(expr, BinaryExpression):
            self._visit_expression(expr.left)
            self._visit_expression(expr.right)
            if isinstance(expr.left, StringLiteral) and isinstance(expr.right, StringLiteral):
                combined = expr.left.value + expr.right.value
                self._check_secret_in_string(combined, _loc(expr))
        elif isinstance(expr, MemberExpression):
            self._visit_expression(expr.object)
        elif hasattr(expr, "expression"):
            self._visit_expression(expr.expression)
        elif hasattr(expr, "operand"):
            self._visit_expression(expr.operand)

    def _check_variable_declaration(self, stmt: VariableDeclaration) -> None:
        if stmt.initializer is not None:
            self._visit_expression(stmt.initializer)
        if stmt.name and stmt.initializer:
            name_lower = stmt.name.lower()
            if any(kw in name_lower for kw in ("api_key", "secret", "password", "token", "credential")):
                if hasattr(stmt.initializer, "value") and isinstance(stmt.initializer.value, str):
                    val = stmt.initializer.value
                    if len(val) > 8 and not val.startswith("$"):
                        self.diagnostics.append(SecurityDiagnostic(
                            message=f"Possible hardcoded secret in variable '{stmt.name}'",
                            code="S001",
                            severity="warning",
                            location=_loc(stmt),
                        ))

    def _check_function_declaration(self, stmt: FunctionDeclaration) -> None:
        name_lower = stmt.name.lower()
        if name_lower in _DANGEROUS_API_NAMES:
            self.diagnostics.append(SecurityDiagnostic(
                message=f"Dangerous function name '{stmt.name}' resembles unsafe API",
                code="S002",
                severity="warning",
                location=_loc(stmt),
            ))

    def _check_call_expression(self, expr: CallExpression) -> None:
        callee = None
        if isinstance(expr.callee, IdentifierExpression):
            callee = expr.callee.name
        if callee and callee in _DANGEROUS_API_NAMES:
            self.diagnostics.append(SecurityDiagnostic(
                message=f"Call to potentially dangerous function '{callee}'",
                code="S003",
                severity="warning",
                location=_loc(expr),
            ))

    def _check_string_literal(self, expr: StringLiteral) -> None:
        self._check_secret_in_string(expr.value, _loc(expr))

        for kw in _DANGEROUS_KEYWORDS:
            if kw in expr.value.lower():
                self.diagnostics.append(SecurityDiagnostic(
                    message=f"String literal contains potentially dangerous shell pattern: '{kw}'",
                    code="S004",
                    severity="warning",
                    location=_loc(expr),
                ))

    def _check_secret_in_string(self, value: str, location: Any) -> None:
        for pattern in _SECRET_PATTERNS:
            if pattern.search(value):
                self.diagnostics.append(SecurityDiagnostic(
                    message="String literal may contain hardcoded secret or credential",
                    code="S005",
                    severity="warning",
                    location=location,
                ))
                break

    def _check_assignment(self, stmt: AssignmentStatement) -> None:
        if hasattr(stmt.target, "name"):
            name_lower = stmt.target.name.lower()
            if any(kw in name_lower for kw in ("api_key", "secret", "password", "token", "credential")):
                if hasattr(stmt.value, "value") and isinstance(stmt.value, StringLiteral):
                    val = stmt.value.value
                    if len(val) > 8 and not val.startswith("$"):
                        self.diagnostics.append(SecurityDiagnostic(
                            message=f"Possible hardcoded secret in assignment to '{stmt.target.name}'",
                            code="S001",
                            severity="warning",
                            location=_loc(stmt),
                        ))


def _loc(node: Any) -> Any:
    return getattr(node, "location", None)
