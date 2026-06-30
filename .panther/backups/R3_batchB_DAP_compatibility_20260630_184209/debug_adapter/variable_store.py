from __future__ import annotations

from collections import OrderedDict
from typing import Any

from .variable_references import VariableReferenceService


class DAPVariable(dict):
    def __getattr__(self, key):
        try:
            return self[key]
        except KeyError as exc:
            raise AttributeError(key) from exc


class DebugVariableStore:
    """Compatibility variable store for legacy and current DAP tests.

    Supports the newer scope-based API used by H4.3 and the older global
    set/get/variables API used by earlier batches.
    """

    def __init__(self):
        self.references = VariableReferenceService()
        self._scopes: OrderedDict[str, dict[str, Any]] = OrderedDict()
        self.globals: dict[str, Any] = {}

    def create_scope(self, name: str, variables=None):
        self._scopes[str(name)] = dict(variables or {})
        return self.get_scope(name)

    def has_scope(self, name: str) -> bool:
        return str(name) in self._scopes

    def get_scope(self, name: str):
        key = str(name)
        if key not in self._scopes:
            raise KeyError(name)
        return {"name": key, "variables": self.variables(key)}

    def clear_scope(self, name: str):
        key = str(name)
        if key not in self._scopes:
            raise KeyError(name)
        del self._scopes[key]

    def clear_all(self):
        self._scopes.clear()
        self.globals.clear()
        self.references = VariableReferenceService()

    def snapshot(self):
        scopes = [self.get_scope(name) for name in self._scopes.keys()]
        return {"scopeCount": len(scopes), "scopes": scopes}

    def assert_store_contract(self):
        snap = self.snapshot()
        return isinstance(snap, dict) and "scopeCount" in snap and "scopes" in snap

    def set_variable(self, scope: str, name: str, value: Any):
        key = str(scope)
        if key not in self._scopes:
            raise KeyError(scope)
        self._scopes[key][str(name)] = value
        return self.get_variable(key, name)

    def get_variable(self, scope: str, name: str):
        key = str(scope)
        if key not in self._scopes:
            raise KeyError(scope)
        n = str(name)
        if n not in self._scopes[key]:
            raise KeyError(name)
        return DAPVariable(self.references.variable(n, self._scopes[key][n]))

    def variables(self, scope: str | None = None):
        if scope is None:
            return [DAPVariable(self.references.variable(k, self.globals[k])) for k in sorted(self.globals)]
        key = str(scope)
        if key not in self._scopes:
            raise KeyError(scope)
        return [DAPVariable(v) for v in self.references.variables_from_mapping(self._scopes[key])]

    def children(self, variables_reference: int):
        return [DAPVariable(v) for v in self.references.children(variables_reference)]

    # Legacy global API
    def set(self, name, value):
        self.globals[str(name)] = value
        return self.get(name)

    def get(self, name):
        n = str(name)
        if n not in self.globals:
            raise KeyError(name)
        return DAPVariable(self.references.variable(n, self.globals[n]))


class VariableStore(DebugVariableStore):
    pass
