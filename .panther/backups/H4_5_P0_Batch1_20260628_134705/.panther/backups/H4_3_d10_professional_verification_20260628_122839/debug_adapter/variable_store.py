from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from .variable_references import VariableReferenceService


@dataclass(slots=True)
class VariableScopeRecord:
    name: str
    variables: Dict[str, Any] = field(default_factory=dict)
    scope_reference: int = 0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "variables": dict(self.variables),
            "scopeReference": int(self.scope_reference),
        }


class VariableStore:
    """
    H4.3 D3 professional variable store.

    Responsibilities:
    - Own named debugger scopes.
    - Store local/global/runtime variables.
    - Return DAP-compatible variables.
    - Preserve variablesReference child lookup from D2.
    """

    def __init__(self, reference_service: Optional[VariableReferenceService] = None) -> None:
        self.reference_service = reference_service or VariableReferenceService()
        self._scopes: Dict[str, VariableScopeRecord] = {}

    def create_scope(self, name: str, variables: Optional[Dict[str, Any]] = None) -> VariableScopeRecord:
        scope = VariableScopeRecord(name=str(name), variables=dict(variables or {}))
        self._scopes[scope.name] = scope
        return scope

    def has_scope(self, name: str) -> bool:
        return str(name) in self._scopes

    def get_scope(self, name: str) -> VariableScopeRecord:
        key = str(name)
        if key not in self._scopes:
            raise KeyError(f"unknown variable scope: {key}")
        return self._scopes[key]

    def set_variable(self, scope: str, name: str, value: Any) -> Dict[str, Any]:
        if not self.has_scope(scope):
            self.create_scope(scope)
        record = self.get_scope(scope)
        record.variables[str(name)] = value
        return self.reference_service.variable(str(name), value)

    def get_variable(self, scope: str, name: str) -> Dict[str, Any]:
        record = self.get_scope(scope)
        key = str(name)
        if key not in record.variables:
            raise KeyError(f"unknown variable in scope {scope}: {key}")
        return self.reference_service.variable(key, record.variables[key])

    def variables(self, scope: str) -> List[Dict[str, Any]]:
        record = self.get_scope(scope)
        return self.reference_service.variables_from_mapping(record.variables)

    def children(self, variables_reference: int) -> List[Dict[str, Any]]:
        return self.reference_service.children(int(variables_reference))

    def clear_scope(self, scope: str) -> None:
        self._scopes.pop(str(scope), None)

    def clear_all(self) -> None:
        self._scopes.clear()
        self.reference_service.allocator.clear()

    def scopes(self) -> List[Dict[str, Any]]:
        return [scope.to_dict() for scope in self._scopes.values()]

    def snapshot(self) -> Dict[str, Any]:
        return {
            "scopeCount": len(self._scopes),
            "scopes": self.scopes(),
            "references": self.reference_service.stats(),
        }

    def assert_store_contract(self) -> bool:
        snap = self.snapshot()
        if "scopeCount" not in snap:
            raise AssertionError("snapshot missing scopeCount")
        if "scopes" not in snap:
            raise AssertionError("snapshot missing scopes")
        if "references" not in snap:
            raise AssertionError("snapshot missing references")
        return True


class DebugVariableStore(VariableStore):
    """Public professional alias used by later H4.3 phases."""
    pass
