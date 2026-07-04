from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass(frozen=True)
class SemanticDiagnostic:
    message: str = ""
    code: str = ""
    location: Any = None

    def __str__(self) -> str:
        prefix = f"[{self.code}]" if self.code else ""
        loc = f" at {self.location}" if self.location is not None else ""
        return f"{prefix}{loc}: {self.message}"


@dataclass(frozen=True)
class SemanticError(SemanticDiagnostic):
    pass


@dataclass(frozen=True)
class SemanticWarning(SemanticDiagnostic):
    pass
