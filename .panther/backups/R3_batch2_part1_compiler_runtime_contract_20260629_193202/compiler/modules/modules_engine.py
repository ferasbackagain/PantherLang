#!/usr/bin/env python3
from __future__ import annotations

import re

class PantherModuleError(Exception):
    pass

MODULE_NAME_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$")

def validate_module_name(name: str) -> None:
    if not MODULE_NAME_RE.fullmatch(name):
        raise PantherModuleError(f"Invalid module name: {name}")

def validate_imports(imports: list[str]) -> None:
    seen = set()
    for item in imports:
        validate_module_name(item)
        if item in seen:
            raise PantherModuleError(f"Duplicate import: {item}")
        seen.add(item)
