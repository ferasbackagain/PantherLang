from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Protocol, runtime_checkable


@dataclass(frozen=True)
class SourceLocation:
    line: int
    column: int
    index: int = 0

    def to_dict(self) -> dict[str, int]:
        return {"line": self.line, "column": self.column, "index": self.index}


@dataclass(frozen=True)
class ASTNode:
    location: SourceLocation | None = None
    metadata: dict[str, Any] = field(default_factory=dict)

    @property
    def node_type(self) -> str:
        return self.__class__.__name__

    def children(self) -> tuple["ASTNode", ...]:
        return ()

    def accept(self, visitor: "ASTVisitorProtocol") -> Any:
        method_name = f"visit_{self.node_type}"
        method = getattr(visitor, method_name, None)
        if method is None:
            method = getattr(visitor, "generic_visit")
        return method(self)


@runtime_checkable
class ASTVisitorProtocol(Protocol):
    def generic_visit(self, node: ASTNode) -> Any:
        ...
