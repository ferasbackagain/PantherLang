from dataclasses import dataclass
from typing import List

@dataclass
class Diagnostic:
    level: str
    message: str
    line: int = 0
    column: int = 0

    def format(self) -> str:
        location = f"{self.line}:{self.column}" if self.line else "unknown"
        return f"[{self.level.upper()}] {location} - {self.message}"

class DiagnosticBag:
    def __init__(self):
        self.items: List[Diagnostic] = []

    def error(self, message: str, line: int = 0, column: int = 0):
        self.items.append(Diagnostic("error", message, line, column))

    def warning(self, message: str, line: int = 0, column: int = 0):
        self.items.append(Diagnostic("warning", message, line, column))

    def has_errors(self) -> bool:
        return any(item.level == "error" for item in self.items)

    def print_all(self):
        for item in self.items:
            print(item.format())
