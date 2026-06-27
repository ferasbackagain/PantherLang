from __future__ import annotations
from dataclasses import dataclass, field
from typing import Any, Dict, List
@dataclass(slots=True)
class OptimizationNode:
    kind: str
    value: Any = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    children: List["OptimizationNode"] = field(default_factory=list)
    def validate(self) -> None:
        if not self.kind or not isinstance(self.kind, str): raise ValueError("optimization node kind must be a non-empty string")
        for child in self.children: child.validate()
    def to_dict(self) -> Dict[str, Any]:
        return {"kind": self.kind, "value": self.value, "metadata": self.metadata, "children": [c.to_dict() for c in self.children]}
@dataclass(slots=True)
class OptimizationUnit:
    name: str
    nodes: List[OptimizationNode] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    def validate(self) -> None:
        if not self.name: raise ValueError("optimization unit name is required")
        if not self.nodes: raise ValueError("optimization unit must contain at least one node")
        for node in self.nodes: node.validate()
    def to_dict(self) -> Dict[str, Any]:
        return {"name": self.name, "nodes": [n.to_dict() for n in self.nodes], "metadata": self.metadata}
