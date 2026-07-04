from __future__ import annotations

from typing import Any

from compiler.ast import (
    ArrayLiteral,
    BinaryExpression,
    BooleanLiteral,
    CallExpression,
    Expression,
    FunctionDeclaration,
    GroupingExpression,
    IdentifierExpression,
    IndexExpression,
    MemberExpression,
    NullLiteral,
    NumberLiteral,
    ObjectLiteral,
    ReturnStatement,
    StringLiteral,
    UnaryExpression,
    VariableDeclaration,
)
from .types import (
    AnyType,
    BoolType,
    FloatType,
    IntType,
    NullType,
    StringType,
    TypeBase,
    get_common_type,
    is_assignable,
)


_LITERAL_TYPES: dict[type, TypeBase] = {
    NumberLiteral: IntType,
    StringLiteral: StringType,
    BooleanLiteral: BoolType,
    NullLiteral: NullType,
}

_TYPE_NAME_MAP: dict[str, TypeBase] = {
    "int": IntType,
    "float": FloatType,
    "string": StringType,
    "bool": BoolType,
    "null": NullType,
    "any": AnyType,
}


class TypeChecker:
    def __init__(self) -> None:
        self.diagnostics: list[SemanticDiagnostic] = []
        self._env: dict[str, TypeBase] = {}
        self._functions: dict[str, tuple[tuple[str | None, ...], str | None]] = {}

    def resolve_type_name(self, name: str | None) -> TypeBase:
        if name is None:
            return AnyType
        return _TYPE_NAME_MAP.get(name, AnyType)

    def infer_type(self, expr: Expression | None) -> TypeBase:
        if expr is None:
            return NullType

        literal_type = _LITERAL_TYPES.get(type(expr))
        if literal_type is not None:
            if isinstance(expr, NumberLiteral) and isinstance(expr.value, float):
                return FloatType
            return literal_type

        if isinstance(expr, IdentifierExpression):
            return self._env.get(expr.name, AnyType)

        if isinstance(expr, UnaryExpression):
            operand = self.infer_type(expr.operand)
            if expr.operator == "!":
                if operand is not BoolType and operand is not AnyType:
                    self._error(f"Operator '!' requires bool operand, got {operand}", expr)
                return BoolType
            if expr.operator in ("+", "-"):
                if operand not in (IntType, FloatType, AnyType):
                    self._error(f"Operator '{expr.operator}' requires numeric operand, got {operand}", expr)
                return operand
            return operand

        if isinstance(expr, BinaryExpression):
            left = self.infer_type(expr.left)
            right = self.infer_type(expr.right)
            common = get_common_type(left, right)
            numeric_ops = {"+", "-", "*", "/", "%", "**"}
            compare_ops = {">", ">=", "<", "<=", "==", "!="}
            logical_ops = {"&&", "||"}
            if expr.operator in numeric_ops:
                if left not in (IntType, FloatType, AnyType):
                    self._error(f"Operator '{expr.operator}' requires numeric operands, got {left}", expr)
                if right not in (IntType, FloatType, AnyType):
                    self._error(f"Operator '{expr.operator}' requires numeric operands, got {right}", expr)
                return common
            if expr.operator in compare_ops:
                return BoolType
            if expr.operator in logical_ops:
                if left is not BoolType and left is not AnyType:
                    self._error(f"Operator '{expr.operator}' requires bool operands, got {left}", expr)
                if right is not BoolType and right is not AnyType:
                    self._error(f"Operator '{expr.operator}' requires bool operands, got {right}", expr)
                return BoolType
            return AnyType

        if isinstance(expr, GroupingExpression):
            return self.infer_type(expr.expression)

        if isinstance(expr, CallExpression):
            fn_name = None
            if isinstance(expr.callee, IdentifierExpression):
                fn_name = expr.callee.name
            for arg in expr.arguments:
                self.infer_type(arg)
            if fn_name in self._functions:
                _, return_type = self._functions[fn_name]
                return self.resolve_type_name(return_type)
            if fn_name is not None and fn_name in self._env:
                return self._env[fn_name]
            return AnyType

        if isinstance(expr, MemberExpression):
            self.infer_type(expr.object)
            return AnyType

        if isinstance(expr, ArrayLiteral):
            return AnyType

        if isinstance(expr, ObjectLiteral):
            return AnyType

        if isinstance(expr, IndexExpression):
            self.infer_type(expr.object)
            self.infer_type(expr.index)
            return AnyType

        return AnyType

    def declare(self, name: str, declared_type: TypeBase) -> None:
        self._env[name] = declared_type

    def declare_function(
        self, name: str, param_types: tuple[str | None, ...], return_type: str | None
    ) -> None:
        self._functions[name] = (param_types, return_type)
        self._env[name] = self.resolve_type_name(return_type)

    def check_variable_declaration(self, stmt: VariableDeclaration) -> None:
        declared = self.resolve_type_name(stmt.var_type)
        if stmt.var_type is not None:
            self.declare(stmt.name, declared)
        if stmt.initializer is not None:
            actual = self.infer_type(stmt.initializer)
            if stmt.var_type is not None and not is_assignable(actual, declared):
                self._error(
                    f"Cannot assign {actual} to variable '{stmt.name}' of type {declared}",
                    stmt,
                )

    def check_assignment(self, target: str, value: Expression) -> bool:
        expected = self._env.get(target, AnyType)
        actual = self.infer_type(value)
        if not is_assignable(actual, expected):
            self._error(f"Cannot assign {actual} to variable '{target}' of type {expected}", value)
            return False
        return True

    def check_function_declaration(self, stmt: FunctionDeclaration) -> None:
        self.declare_function(stmt.name, stmt.param_types, stmt.return_type)
        if stmt.return_type is not None:
            expected_ret = self.resolve_type_name(stmt.return_type)
            if stmt.body is not None:
                for s in stmt.body.statements:
                    if isinstance(s, ReturnStatement) and s.expression is not None:
                        actual = self.infer_type(s.expression)
                        if not is_assignable(actual, expected_ret):
                            self._error(
                                f"Return type mismatch: expected {expected_ret}, got {actual}",
                                s,
                            )

    def _error(self, message: str, location: Any = None) -> None:
        from compiler.semantic.diagnostics import SemanticError
        loc = getattr(location, "location", None) if location is not None else None
        self.diagnostics.append(SemanticError(
            message=message,
            code="T001",
            location=loc,
        ))


def check_type(expr: Expression, env: dict[str, TypeBase] | None = None) -> tuple[TypeBase, list[SemanticDiagnostic]]:
    checker = TypeChecker()
    if env is not None:
        checker._env = dict(env)
    result = checker.infer_type(expr)
    return result, checker.diagnostics
