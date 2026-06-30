from __future__ import annotations

from .variable_references import (
    ReferenceEntry,
    VariableChild,
    VariableReferenceAllocator,
    VariableReferenceEntry,
    VariableReferenceResolver,
    VariableReferenceService,
    VariableReferenceStore,
)
from .variable_store import DAPVariable, DebugVariableStore, VariableStore
from .stack_frames import StackFrameStore
from .threads import ThreadStore
from .scopes import ScopeStore
from .evaluate import EvaluateEngine
from .watch_expressions import WatchExpressionStore


class VariablesCore:
    """Small facade preserving the historical VariablesCore public contract."""

    def __init__(self):
        self.store = VariableStore()
        self.references = self.store.references

    def create_scope(self, name, variables=None):
        return self.store.create_scope(name, variables)

    def variables(self, scope):
        return self.store.variables(scope)

    def children(self, variables_reference):
        return self.store.children(variables_reference)

    def snapshot(self):
        return self.store.snapshot()


__all__ = [
    "ReferenceEntry",
    "VariableChild",
    "VariableReferenceEntry",
    "VariableReferenceAllocator",
    "VariableReferenceResolver",
    "VariableReferenceService",
    "VariableReferenceStore",
    "DAPVariable",
    "DebugVariableStore",
    "VariableStore",
    "VariablesCore",
    "StackFrameStore",
    "ThreadStore",
    "ScopeStore",
    "EvaluateEngine",
    "WatchExpressionStore",
]
