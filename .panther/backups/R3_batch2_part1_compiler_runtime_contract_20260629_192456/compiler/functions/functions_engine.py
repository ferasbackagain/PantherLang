#!/usr/bin/env python3
from __future__ import annotations
import re

class PantherFunctionError(Exception):
    pass

CALL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*\((.*?)\)\s*$")

def split_args(text: str) -> list[str]:
    text = text.strip()
    if not text:
        return []
    args = []
    current = []
    in_string = False
    escape = False
    for ch in text:
        if escape:
            current.append(ch)
            escape = False
            continue
        if ch == "\\":
            current.append(ch)
            escape = True
            continue
        if ch == '"':
            current.append(ch)
            in_string = not in_string
            continue
        if ch == "," and not in_string:
            args.append("".join(current).strip())
            current = []
            continue
        current.append(ch)
    if in_string:
        raise PantherFunctionError("Unclosed string in function arguments")
    last = "".join(current).strip()
    if last:
        args.append(last)
    return args

def parse_call(line: str):
    m = CALL_RE.match(line.strip())
    if not m:
        return None
    return {"kind": "FunctionCall", "name": m.group(1), "args": split_args(m.group(2))}
