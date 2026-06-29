from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, Iterable, List, Optional, Tuple

from .variables_core import DebugVariable, VariableFactory, VariablesCore


@dataclass(slots=True)
class ReferenceEntry:
    reference: int
    name: str
    value: Any
    parent_reference: int = 0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "reference": self.reference,
            "name": self.name,
            "value": self.value,
            "parentReference": self.parent_reference,
        }


class VariableReferenceAllocator:
    """
    Deterministic variablesReference allocator for PantherLang DAP variables.

    DAP rule:
    - variablesReference == 0 means no children.
    - variablesReference > 0 means the client may call variables(reference).
    """

    def __init__(self, start: int = 1000) -> None:
        if start < 1:
            raise ValueError("reference start must be >= 1")
        self._next = int(start)
        self._entries: Dict[int, ReferenceEntry] = {}

    def allocate(self, name: str, value: Any, parent_reference: int = 0) -> int:
        ref = self._next
        self._next += 1
        self._entries[ref] = ReferenceEntry(
            reference=ref,
            name=str(name),
            value=value,
            parent_reference=int(parent_reference),
        )
        return ref

    def has(self, reference: int) -> bool:
        return int(reference) in self._entries

    def get(self, reference: int) -> ReferenceEntry:
        ref = int(reference)
        if ref not in self._entries:
            raise KeyError(f"unknown variablesReference: {ref}")
        return self._entries[ref]

    def clear(self) -> None:
        self._entries.clear()

    def count(self) -> int:
        return len(self._entries)

    def entries(self) -> List[Dict[str, Any]]:
        return [entry.to_dict() for entry in self._entries.values()]


class VariableReferenceResolver:
    """Resolves Python/Panther runtime values into child DebugVariable objects."""

    def __init__(self, factory: Optional[VariableFactory] = None) -> None:
        self.factory = factory or VariableFactory()

    def children_for(self, name: str, value: Any) -> List[DebugVariable]:
        if isinstance(value, dict):
            return [
                self.factory.create(
                    name=str(child_name),
                    value=child_value,
                    evaluate_name=f"{name}.{child_name}",
                )
                for child_name, child_value in value.items()
            ]

        if isinstance(value, (list, tuple)):
            return [
                self.factory.create(
                    name=str(index),
                    value=child_value,
                    evaluate_name=f"{name}[{index}]",
                )
                for index, child_value in enumerate(value)
            ]

        return []


class VariableReferenceService:
    """
    H4.3 D2 reference-aware variables service.

    D1 creates scalar DAP variables.
    D2 adds deterministic child-reference allocation and resolution.
    """

    def __init__(
        self,
        allocator: Optional[VariableReferenceAllocator] = None,
        resolver: Optional[VariableReferenceResolver] = None,
        core: Optional[VariablesCore] = None,
    ) -> None:
        self.allocator = allocator or VariableReferenceAllocator()
        self.resolver = resolver or VariableReferenceResolver()
        self.core = core or VariablesCore()

    def variable(self, name: str, value: Any, parent_reference: int = 0) -> Dict[str, Any]:
        children = self.resolver.children_for(name, value)
        variables_reference = 0

        if children:
            variables_reference = self.allocator.allocate(
                name=name,
                value=value,
                parent_reference=parent_reference,
            )

        return self.core.variable(
            name=name,
            value=value,
            variables_reference=variables_reference,
            evaluate_name=name,
        )

    def variables_from_mapping(self, values: Dict[str, Any], parent_reference: int = 0) -> List[Dict[str, Any]]:
        return [
            self.variable(str(name), value, parent_reference=parent_reference)
            for name, value in values.items()
        ]

    def variables_from_iterable(self, values: Iterable[Any], parent_name: str = "items", parent_reference: int = 0) -> List[Dict[str, Any]]:
        return [
            self.variable(str(index), value, parent_reference=parent_reference)
            for index, value in enumerate(values)
        ]

    def children(self, reference: int) -> List[Dict[str, Any]]:
        entry = self.allocator.get(reference)
        children = self.resolver.children_for(entry.name, entry.value)
        return [
            self.variable(child.name, child.value, parent_reference=reference)
            for child in children
        ]

    def assert_reference_contract(self, variable: Dict[str, Any]) -> bool:
        self.core.assert_variable_contract(variable)
        if variable["variablesReference"] < 0:
            raise AssertionError("variablesReference cannot be negative")
        return True

    def stats(self) -> Dict[str, Any]:
        return {
            "referenceCount": self.allocator.count(),
            "entries": self.allocator.entries(),
        }
