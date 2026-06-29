#!/usr/bin/env python3
from __future__ import annotations

import ast
from typing import Any

class PantherStdlibError(Exception):
    pass

SUPPORTED = {
    "std.text.upper",
    "std.text.lower",
    "std.math.add",
    "std.math.mul",
    "std.io.echo",
}

def _eval_arg(node: ast.AST, symbols: dict[str, Any]) -> Any:
    if isinstance(node, ast.Constant):
        if isinstance(node.value, (str, int, bool)):
            return node.value
        raise PantherStdlibError("Unsupported stdlib argument constant")
    if isinstance(node, ast.Name):
        if node.id in symbols:
            return symbols[node.id]
        raise PantherStdlibError(f"Undefined stdlib argument symbol: {node.id}")
    raise PantherStdlibError("Unsupported stdlib argument expression")

def _name_from_node(node: ast.AST) -> str:
    if isinstance(node, ast.Name):
        return node.id
    if isinstance(node, ast.Attribute):
        return _name_from_node(node.value) + "." + node.attr
    raise PantherStdlibError("Unsupported stdlib call target")

def is_stdlib_call(expr: str) -> bool:
    text = expr.strip()
    return text.startswith("std.")

def evaluate_stdlib_call(expr: str, symbols: dict[str, Any]) -> Any:
    try:
        parsed = ast.parse(expr.strip(), mode="eval")
    except Exception as exc:
        raise PantherStdlibError(f"Invalid stdlib expression: {expr}") from exc

    if not isinstance(parsed.body, ast.Call):
        raise PantherStdlibError(f"Invalid stdlib call: {expr}")

    name = _name_from_node(parsed.body.func)
    if name not in SUPPORTED:
        raise PantherStdlibError(f"Unsupported stdlib function: {name}")

    args = [_eval_arg(arg, symbols) for arg in parsed.body.args]

    if name == "std.text.upper":
        if len(args) != 1:
            raise PantherStdlibError("std.text.upper expects 1 argument")
        return str(args[0]).upper()

    if name == "std.text.lower":
        if len(args) != 1:
            raise PantherStdlibError("std.text.lower expects 1 argument")
        return str(args[0]).lower()

    if name == "std.math.add":
        if len(args) != 2:
            raise PantherStdlibError("std.math.add expects 2 arguments")
        if not all(isinstance(x, int) for x in args):
            raise PantherStdlibError("std.math.add requires integer arguments")
        return args[0] + args[1]

    if name == "std.math.mul":
        if len(args) != 2:
            raise PantherStdlibError("std.math.mul expects 2 arguments")
        if not all(isinstance(x, int) for x in args):
            raise PantherStdlibError("std.math.mul requires integer arguments")
        return args[0] * args[1]

    if name == "std.io.echo":
        if len(args) != 1:
            raise PantherStdlibError("std.io.echo expects 1 argument")
        return str(args[0])

    raise PantherStdlibError(f"Unsupported stdlib function: {name}")
