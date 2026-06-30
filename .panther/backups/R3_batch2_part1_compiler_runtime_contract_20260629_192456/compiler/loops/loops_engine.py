#!/usr/bin/env python3
from __future__ import annotations
import re
from typing import Any

class PantherLoopError(Exception):
    pass

FOR_RE = re.compile(r"^for\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\s+(.+)\.\.(.+)\s*\{\s*$")

def _clean(line: str) -> str:
    return line.strip()

def parse_loop_blocks(lines: list[str]) -> list[dict[str, Any]]:
    nodes: list[dict[str, Any]] = []
    i = 0
    while i < len(lines):
        raw = lines[i]
        line = _clean(raw)
        if not line or line.startswith("#"):
            i += 1
            continue
        if not line.startswith("for "):
            nodes.append({"kind": "RawLine", "line": i + 1, "source": raw})
            i += 1
            continue
        m = FOR_RE.match(line)
        if not m:
            raise PantherLoopError(f"Invalid for loop at line {i + 1}. Expected: for i in 1..3 {{")
        var, start_expr, end_expr = m.group(1), m.group(2).strip(), m.group(3).strip()
        i += 1
        body_lines: list[str] = []
        while i < len(lines):
            current = _clean(lines[i])
            if current == "}":
                i += 1
                break
            body_lines.append(lines[i])
            i += 1
        else:
            raise PantherLoopError("Unclosed for loop block")
        nodes.append({"kind": "For", "line": i, "var": var, "start_expr": start_expr, "end_expr": end_expr, "body_lines": body_lines})
    return nodes

def validate_loop_range(start: Any, end: Any) -> tuple[int, int]:
    if not isinstance(start, int) or not isinstance(end, int):
        raise PantherLoopError("Loop range bounds must be integers")
    if end < start:
        raise PantherLoopError("Loop range end must be greater than or equal to start")
    if end - start > 10000:
        raise PantherLoopError("Loop range too large")
    return start, end
