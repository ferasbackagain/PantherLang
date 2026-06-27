#!/usr/bin/env python3
from __future__ import annotations
from typing import Any
from compiler.expressions.expression_engine import ExpressionEngine, PantherExpressionError

class PantherControlFlowError(Exception):
    pass

def _clean(line: str) -> str:
    return line.strip()

def parse_if_blocks(lines: list[str]) -> list[dict[str, Any]]:
    nodes: list[dict[str, Any]] = []
    i = 0
    while i < len(lines):
        raw = lines[i]
        line = _clean(raw)
        if not line or line.startswith("#"):
            i += 1
            continue
        if not line.startswith("if "):
            nodes.append({"kind": "RawLine", "line": i + 1, "source": raw})
            i += 1
            continue
        if "{" not in line:
            raise PantherControlFlowError(f"Invalid if statement at line {i + 1}: missing '{{'")
        condition = line[len("if "):line.rfind("{")].strip()
        if not condition:
            raise PantherControlFlowError(f"Invalid if statement at line {i + 1}: empty condition")
        i += 1
        then_lines: list[str] = []
        while i < len(lines):
            current = _clean(lines[i])
            if current == "}":
                i += 1
                break
            if current.startswith("} else"):
                break
            then_lines.append(lines[i])
            i += 1
        else:
            raise PantherControlFlowError("Unclosed if block")
        else_lines: list[str] = []
        if i < len(lines):
            maybe_else = _clean(lines[i])
            if maybe_else.startswith("else") or maybe_else.startswith("} else"):
                if "{" not in maybe_else:
                    raise PantherControlFlowError(f"Invalid else statement at line {i + 1}: missing '{{'")
                i += 1
                while i < len(lines):
                    current = _clean(lines[i])
                    if current == "}":
                        i += 1
                        break
                    else_lines.append(lines[i])
                    i += 1
                else:
                    raise PantherControlFlowError("Unclosed else block")
        nodes.append({"kind": "If", "line": i, "condition": condition, "then_lines": then_lines, "else_lines": else_lines})
    return nodes

def evaluate_condition(condition: str, symbols: dict[str, Any]) -> bool:
    try:
        value = ExpressionEngine(symbols).evaluate(condition)
    except PantherExpressionError as exc:
        raise PantherControlFlowError(str(exc)) from exc
    if isinstance(value, bool):
        return value
    if isinstance(value, int):
        return value != 0
    if isinstance(value, str):
        return bool(value)
    return False
