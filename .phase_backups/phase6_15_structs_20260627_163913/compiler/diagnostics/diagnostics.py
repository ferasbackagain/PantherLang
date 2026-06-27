#!/usr/bin/env python3
from __future__ import annotations
from dataclasses import dataclass, asdict
from typing import Any

@dataclass
class Diagnostic:
    level: str
    code: str
    message: str
    line: int = 0
    column: int = 0
    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

class DiagnosticBag:
    def __init__(self) -> None:
        self.items: list[Diagnostic] = []
    def error(self, code: str, message: str, line: int = 0, column: int = 0) -> None:
        self.items.append(Diagnostic("error", code, message, line, column))
    def warning(self, code: str, message: str, line: int = 0, column: int = 0) -> None:
        self.items.append(Diagnostic("warning", code, message, line, column))
    def has_errors(self) -> bool:
        return any(item.level == "error" for item in self.items)
    def to_list(self) -> list[dict[str, Any]]:
        return [item.to_dict() for item in self.items]
