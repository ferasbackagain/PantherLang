#!/usr/bin/env python3
from __future__ import annotations
import re

class PantherStructError(Exception):
    pass

FIELD_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

def validate_struct(name: str, fields: list[str]) -> None:
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
        raise PantherStructError(f"Invalid struct name: {name}")
    if not fields:
        raise PantherStructError(f"Struct {name} must have at least one field")
    seen: set[str] = set()
    for field in fields:
        if not FIELD_RE.fullmatch(field):
            raise PantherStructError(f"Invalid struct field: {field}")
        if field in seen:
            raise PantherStructError(f"Duplicate struct field: {field}")
        seen.add(field)
