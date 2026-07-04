from __future__ import annotations

# PANTHER_COMPARISON_RUNTIME_FIX1_V2_START
# PantherLang comparison contract helpers — v1.1.5 RC1b
# PDL-005: comparison operators require compatible operand types.
def _panther_runtime_type_name(value):
    # bool must be checked before int because Python bool is a subclass of int.
    if isinstance(value, bool):
        return "bool"
    if isinstance(value, int):
        return "int"
    if isinstance(value, float):
        return "float"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        return "array"
    if isinstance(value, dict):
        return "object"
    if value is None:
        return "null"
    return type(value).__name__


def _panther_comparison_operator_name(operator):
    raw = getattr(operator, "value", operator)
    raw = str(raw)
    mapping = {
        "TokenKind.EQUAL_EQUAL": "==",
        "TokenKind.BANG_EQUAL": "!=",
        "TokenKind.NOT_EQUAL": "!=",
        "EQUAL_EQUAL": "==",
        "BANG_EQUAL": "!=",
        "NOT_EQUAL": "!=",
        "==": "==",
        "!=": "!=",
        ">": ">",
        "<": "<",
        ">=": ">=",
        "<=": "<=",
    }
    return mapping.get(raw, raw)


def _panther_require_comparison_compatible(operator, left, right):
    op = _panther_comparison_operator_name(operator)
    if op not in ("==", "!=", ">", "<", ">=", "<="):
        return

    left_type = _panther_runtime_type_name(left)
    right_type = _panther_runtime_type_name(right)

    # null is comparable with any type for equality operators.
    if op in ("==", "!=") and (left_type == "null" or right_type == "null"):
        return

    # Numeric comparisons allow int/float combinations, but not bool.
    numeric = {"int", "float"}
    if left_type in numeric and right_type in numeric:
        return

    # Same runtime type is comparable.
    if left_type == right_type:
        return

    raise RuntimeError(
        "Panther Type Error PT002: Cannot compare values of different types. "
        f"Operator '{op}' cannot be applied to {left_type} and {right_type}. "
        "PantherLang does not perform implicit comparison conversion. "
        "Use to_string(), to_int(), to_float(), to_number(), or to_bool() explicitly."
    )


def _panther_comparable_types(left, right):
    left_type = _panther_runtime_type_name(left)
    right_type = _panther_runtime_type_name(right)

    # null is comparable with any type for equality operators.
    if left_type == "null" or right_type == "null":
        return

    # Numeric comparisons allow int/float combinations, but not bool.
    numeric = {"int", "float"}
    if left_type in numeric and right_type in numeric:
        return

    # Same runtime type is comparable.
    if left_type == right_type:
        return

    raise RuntimeError(
        "Panther Type Error PT002: Cannot compare values of different types. "
        f"Operator '?' cannot be applied to {left_type} and {right_type}. "
        "PantherLang does not perform implicit comparison conversion. "
        "Use to_string(), to_int(), to_float(), to_number(), or to_bool() explicitly."
    )


def _panther_comparison_error(op, left, right):
    return RuntimeError(
        "Panther Type Error PT002: Cannot compare values of different types. "
        f"Operator '{op}' cannot be applied to "
        f"{_panther_runtime_type_name(left)} and {_panther_runtime_type_name(right)}. "
        "PantherLang does not perform implicit comparison conversion. "
        "Use to_string(), to_int(), to_float(), to_number(), or to_bool() explicitly."
    )


def _panther_compare_values(op, left, right):
    if not _panther_comparable_types(left, right):
        raise _panther_comparison_error(op, left, right)
    if op == "==":
        return left == right
    if op == "!=":
        return left != right
    if op == ">":
        return left > right
    if op == "<":
        return left < right
    if op == ">=":
        return left >= right
    if op == "<=":
        return left <= right
    raise RuntimeError(f"Unsupported comparison operator: {op}")
# PANTHER_COMPARISON_RUNTIME_FIX1_V2_END


from typing import Any

from compiler.ast import (
    ArrayLiteral,
    BinaryExpression,
    BooleanLiteral,
    CallExpression,
    Expression,
    GroupingExpression,
    IdentifierExpression,
    IndexExpression,
    MemberExpression,
    NullLiteral,
    NumberLiteral,
    ObjectLiteral,
    StringLiteral,
    UnaryExpression,
)

from .variable_environment import VariableEnvironment


class EvaluationError(Exception):
    pass


_BINARY_OPS: dict[str, Any] = {
    "+": lambda a, b: a + b,
    "-": lambda a, b: a - b,
    "*": lambda a, b: a * b,
    "/": lambda a, b: a // b,
    "%": lambda a, b: a % b,
    "**": lambda a, b: a ** b,
    "==": lambda a, b: a == b,
    "!=": lambda a, b: a != b,
    ">": lambda a, b: a > b,
    ">=": lambda a, b: a >= b,
    "<": lambda a, b: a < b,
    "<=": lambda a, b: a <= b,
    "&&": lambda a, b: a and b,
    "||": lambda a, b: a or b,
}

_UNARY_OPS: dict[str, Any] = {
    "-": lambda a: -a,
    "+": lambda a: a,
    "!": lambda a: not a,
}


class ExpressionEvaluator:
    def __init__(self, environment: VariableEnvironment) -> None:
        self._env = environment

    def evaluate(self, expression: Expression | None) -> Any:
        if expression is None:
            return None
        if isinstance(expression, NumberLiteral):
            return expression.value
        if isinstance(expression, StringLiteral):
            return expression.value
        if isinstance(expression, BooleanLiteral):
            return expression.value
        if isinstance(expression, NullLiteral):
            return None
        if isinstance(expression, IdentifierExpression):
            return self._env.lookup(expression.name)
        if isinstance(expression, UnaryExpression):
            return self._eval_unary(expression)
        if isinstance(expression, BinaryExpression):
            return self._eval_binary(expression)
        if isinstance(expression, GroupingExpression):
            return self.evaluate(expression.expression)
        if isinstance(expression, CallExpression):
            return self._eval_call(expression)
        if isinstance(expression, MemberExpression):
            return self._eval_member(expression)
        if isinstance(expression, ArrayLiteral):
            return [self.evaluate(item) for item in expression.items]
        if isinstance(expression, ObjectLiteral):
            return {key: self.evaluate(val) for key, val in expression.entries}
        if isinstance(expression, IndexExpression):
            return self._eval_index(expression)
        raise EvaluationError(f"Unsupported expression: {type(expression).__name__}")

    def _eval_unary(self, expr: UnaryExpression) -> Any:
        operand = self.evaluate(expr.operand)
        op_fn = _UNARY_OPS.get(expr.operator)
        if op_fn is None:
            raise EvaluationError(f"Unsupported unary operator: {expr.operator}")
        try:
            return op_fn(operand)
        except TypeError as exc:
            raise EvaluationError(f"Type error in unary expression: {exc}") from exc

    def _eval_call(self, expr: CallExpression) -> Any:
        callee_name = None
        if isinstance(expr.callee, IdentifierExpression):
            callee_name = expr.callee.name
        else:
            raise EvaluationError("Only named function calls are supported")
        if self._env.has_type(callee_name):
            struct_def = self._env.lookup_type(callee_name)
            args = [self.evaluate(arg) for arg in expr.arguments]
            field_names = [f.name for f in struct_def.fields]
            instance = dict(zip(field_names, args))
            instance["__type"] = callee_name
            return instance
        func = self._env.lookup_function(callee_name)
        args = [self.evaluate(arg) for arg in expr.arguments]
        return func(*args)

    def _eval_member(self, expr: MemberExpression) -> Any:
        obj = self.evaluate(expr.object)
        if isinstance(obj, dict):
            if expr.property in obj:
                return obj[expr.property]
            raise EvaluationError(f"Struct has no field '{expr.property}'")
        raise EvaluationError(f"Cannot access property on {type(obj).__name__}")

    def _eval_index(self, expr: IndexExpression) -> Any:
        obj = self.evaluate(expr.object)
        index = self.evaluate(expr.index)
        if isinstance(obj, (list, tuple)):
            if not isinstance(index, int):
                raise EvaluationError(f"Array index must be an integer, got {type(index).__name__}")
            try:
                return obj[index]
            except IndexError:
                raise EvaluationError(f"Array index {index} out of range (length {len(obj)})")
        if isinstance(obj, dict):
            if isinstance(index, str):
                if index in obj:
                    return obj[index]
                raise EvaluationError(f"Object has no key '{index}'")
            raise EvaluationError(f"Object key must be a string, got {type(index).__name__}")
        raise EvaluationError(f"Cannot index into {type(obj).__name__}")

    def _eval_binary(self, expr: BinaryExpression) -> Any:
        left = self.evaluate(expr.left)
        right = self.evaluate(expr.right)

        # Comparison operators need type checking
        if expr.operator in ("==", "!=", ">", "<", ">=", "<="):
            _panther_require_comparison_compatible(expr.operator, left, right)
            op_fn = _BINARY_OPS.get(expr.operator)
            if op_fn is None:
                raise EvaluationError(
                    f"Panther Runtime Error PR000: unsupported binary operator '{expr.operator}'"
                )
            try:
                return op_fn(left, right)
            except TypeError as exc:
                raise EvaluationError(
                    f"Panther Type Error PT002: Comparison error: {exc}"
                ) from exc

        op_fn = _BINARY_OPS.get(expr.operator)
        if op_fn is None:
            raise EvaluationError(
                f"Panther Runtime Error PR000: unsupported binary operator '{expr.operator}'"
            )

        if expr.operator in ("/", "%") and right == 0:
            raise EvaluationError(
                "Panther Runtime Error PR001: Division by zero. "
                "The right side of '/' or '%' cannot be 0. "
                "Hint: check the divisor before division."
            )

        if expr.operator == "+" and (isinstance(left, str) != isinstance(right, str)):
            raise EvaluationError(
                "Panther Type Error PT001: Cannot add values of different types. "
                f"Left={type(left).__name__}, Right={type(right).__name__}. "
                "PantherLang does not perform implicit conversion. "
                "Use to_string(), to_int(), to_float(), or to_bool() explicitly."
            )

        try:
            return op_fn(left, right)
        except ZeroDivisionError as exc:
            raise EvaluationError(
                "Panther Runtime Error PR001: Division by zero. "
                "Hint: check the divisor before division."
            ) from exc
        except TypeError as exc:
            raise EvaluationError(
                "Panther Type Error PT001: Invalid binary operation. "
                f"Operator '{expr.operator}' cannot be applied to "
                f"{type(left).__name__} and {type(right).__name__}. "
                "Use explicit conversion when needed."
            ) from exc