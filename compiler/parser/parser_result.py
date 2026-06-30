from __future__ import annotations

from dataclasses import dataclass, field
from typing import Generic, TypeVar

from .diagnostics import ParserDiagnostic

T = TypeVar("T")


@dataclass(frozen=True)
class ParserResult(Generic[T]):
    """Uniform return object for parser entry points."""

    node: T | None = None
    diagnostics: tuple[ParserDiagnostic, ...] = field(default_factory=tuple)

    @property
    def ok(self) -> bool:
        return self.node is not None and not self.diagnostics

    @property
    def has_errors(self) -> bool:
        return bool(self.diagnostics)

    def to_dict(self) -> dict[str, object]:
        return {
            "ok": self.ok,
            "has_errors": self.has_errors,
            "diagnostics": [item.to_dict() for item in self.diagnostics],
        }
