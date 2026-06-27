#!/usr/bin/env python3
from __future__ import annotations
import ast, operator, re
from typing import Any

class PantherExpressionError(Exception):
    pass

class ExpressionEngine:
    BIN_OPS = {ast.Add: operator.add, ast.Sub: operator.sub, ast.Mult: operator.mul, ast.Div: operator.floordiv, ast.Mod: operator.mod}
    CMP_OPS = {ast.Eq: operator.eq, ast.NotEq: operator.ne, ast.Lt: operator.lt, ast.LtE: operator.le, ast.Gt: operator.gt, ast.GtE: operator.ge}
    def __init__(self, symbols: dict[str, Any] | None = None) -> None:
        self.symbols = symbols or {}
    def normalize(self, expr: str) -> str:
        expr = expr.strip()
        expr = re.sub(r"\btrue\b", "True", expr)
        expr = re.sub(r"\bfalse\b", "False", expr)
        return expr
    def evaluate(self, expr: str) -> Any:
        expr = self.normalize(expr)
        if not expr:
            raise PantherExpressionError("Expression cannot be empty")
        try:
            return self._eval(ast.parse(expr, mode="eval").body)
        except PantherExpressionError:
            raise
        except Exception as exc:
            raise PantherExpressionError(f"Invalid expression: {expr}") from exc
    def _eval(self, node: ast.AST) -> Any:
        if isinstance(node, ast.Constant):
            if isinstance(node.value, (int, str, bool)):
                return node.value
            raise PantherExpressionError("Unsupported constant type")
        if isinstance(node, ast.Name):
            if node.id in self.symbols:
                return self.symbols[node.id]
            raise PantherExpressionError(f"Undefined symbol: {node.id}")
        if isinstance(node, ast.UnaryOp) and isinstance(node.op, (ast.USub, ast.UAdd)):
            v = self._eval(node.operand)
            if not isinstance(v, int): raise PantherExpressionError("Unary operator requires integer")
            return -v if isinstance(node.op, ast.USub) else v
        if isinstance(node, ast.BinOp):
            op = type(node.op)
            if op not in self.BIN_OPS: raise PantherExpressionError("Unsupported binary operator")
            l, r = self._eval(node.left), self._eval(node.right)
            if not isinstance(l, int) or not isinstance(r, int): raise PantherExpressionError("Arithmetic requires integers")
            if isinstance(node.op, (ast.Div, ast.Mod)) and r == 0: raise PantherExpressionError("Division by zero")
            return self.BIN_OPS[op](l, r)
        if isinstance(node, ast.Compare):
            current = self._eval(node.left); result = True
            for op, comp in zip(node.ops, node.comparators):
                opt = type(op)
                if opt not in self.CMP_OPS: raise PantherExpressionError("Unsupported comparison operator")
                right = self._eval(comp); result = result and self.CMP_OPS[opt](current, right); current = right
            return result
        raise PantherExpressionError(f"Unsupported expression node: {type(node).__name__}")

def panther_format(value: Any) -> str:
    if value is True: return "true"
    if value is False: return "false"
    return str(value)
