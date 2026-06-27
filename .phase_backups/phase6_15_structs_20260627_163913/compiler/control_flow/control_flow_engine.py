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

        if not line.endswith("{"):
            raise PantherControlFlowError(f"Invalid if statement at line {i + 1}: missing '{{'")

        condition = line[len("if "):-1].strip()
        if not condition:
            raise PantherControlFlowError(f"Invalid if statement at line {i + 1}: empty condition")

        i += 1
        then_lines: list[str] = []
        else_lines: list[str] = []
        mode = "then"
        closed = False

        while i < len(lines):
            current_raw = lines[i]
            current = _clean(current_raw)

            if current == "}":
                closed = True
                i += 1
                break

            if current == "} else {" or current == "}else{":
                mode = "else"
                i += 1
                continue

            if current == "else {":
                mode = "else"
                i += 1
                continue

            if mode == "then":
                then_lines.append(current_raw)
            else:
                else_lines.append(current_raw)

            i += 1

        if not closed:
            raise PantherControlFlowError("Unclosed if block")

        nodes.append({
            "kind": "If",
            "line": i,
            "condition": condition,
            "then_lines": then_lines,
            "else_lines": else_lines,
        })

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
