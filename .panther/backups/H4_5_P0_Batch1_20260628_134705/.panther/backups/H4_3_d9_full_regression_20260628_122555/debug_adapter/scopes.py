from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from .threads import ThreadStore
from .stack_frames import StackFrameStore, DebugStackFrame


@dataclass(slots=True)
class DebugScope:
    """
    PantherLang professional DAP Scope model.

    DAP Scope fields:
    - name
    - variablesReference
    - expensive
    """

    name: str
    variables_reference: int
    expensive: bool = False
    presentation_hint: Optional[str] = None
    named_variables: Optional[int] = None
    indexed_variables: Optional[int] = None
    source: Optional[Dict[str, Any]] = None
    line: Optional[int] = None
    column: Optional[int] = None
    end_line: Optional[int] = None
    end_column: Optional[int] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dap(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "name": str(self.name),
            "variablesReference": int(self.variables_reference),
            "expensive": bool(self.expensive),
        }

        if self.presentation_hint:
            payload["presentationHint"] = self.presentation_hint
        if self.named_variables is not None:
            payload["namedVariables"] = int(self.named_variables)
        if self.indexed_variables is not None:
            payload["indexedVariables"] = int(self.indexed_variables)
        if self.source is not None:
            payload["source"] = dict(self.source)
        if self.line is not None:
            payload["line"] = int(self.line)
        if self.column is not None:
            payload["column"] = int(self.column)
        if self.end_line is not None:
            payload["endLine"] = int(self.end_line)
        if self.end_column is not None:
            payload["endColumn"] = int(self.end_column)
        if self.metadata:
            payload["metadata"] = dict(self.metadata)

        return payload


class ScopeStore:
    """
    H4.3 D6 Scope Store.

    Responsibilities:
    - Create DAP-compatible scopes for stack frames.
    - Bind scopes to D3 VariableStore references.
    - Build scopes response bodies.
    """

    def __init__(self, thread_store: Optional[ThreadStore] = None) -> None:
        self.thread_store = thread_store or ThreadStore()
        self._scope_bindings: Dict[int, List[DebugScope]] = {}
        self._scope_reference_to_frame: Dict[int, int] = {}

    def _frame_store_for_frame_id(self, frame_id: int) -> StackFrameStore:
        for thread in self.thread_store.threads():
            frame_store = self.thread_store.frame_store(thread.id)
            try:
                frame_store.frame(frame_id)
                return frame_store
            except KeyError:
                continue
        raise KeyError(f"unknown stack frame id for scopes: {frame_id}")

    def create_local_scope_for_frame(self, frame_id: int, name: str = "Locals") -> DebugScope:
        frame_store = self._frame_store_for_frame_id(frame_id)
        frame = frame_store.frame(frame_id)

        variables = frame_store.variables_for_frame(frame.id)
        reference = 0

        if variables:
            reference = frame_store.variable_store.reference_service.allocator.allocate(
                name=frame.scope_name(),
                value=dict(frame.variables),
                parent_reference=0,
            )

        scope = DebugScope(
            name=name,
            variables_reference=reference,
            expensive=False,
            named_variables=len(frame.variables),
            indexed_variables=0,
            source=frame.to_dap().get("source"),
            line=frame.line,
            column=frame.column,
            metadata={"frameId": frame.id, "scopeName": frame.scope_name()},
        )

        self._scope_bindings.setdefault(frame.id, [])
        self._scope_bindings[frame.id] = [
            existing for existing in self._scope_bindings[frame.id]
            if existing.name != scope.name
        ]
        self._scope_bindings[frame.id].append(scope)

        if reference:
            self._scope_reference_to_frame[reference] = frame.id

        return scope

    def create_empty_scope(self, frame_id: int, name: str = "Locals") -> DebugScope:
        self._frame_store_for_frame_id(frame_id).frame(frame_id)
        scope = DebugScope(
            name=name,
            variables_reference=0,
            expensive=False,
            named_variables=0,
            indexed_variables=0,
            metadata={"frameId": frame_id},
        )
        self._scope_bindings.setdefault(frame_id, []).append(scope)
        return scope

    def scopes_for_frame(self, frame_id: int) -> List[DebugScope]:
        frame_id = int(frame_id)
        if frame_id not in self._scope_bindings:
            self.create_local_scope_for_frame(frame_id)
        return list(self._scope_bindings.get(frame_id, []))

    def scopes_body(self, frame_id: int) -> Dict[str, Any]:
        return {
            "scopes": [scope.to_dap() for scope in self.scopes_for_frame(frame_id)]
        }

    def variables_for_scope_reference(self, variables_reference: int) -> List[Dict[str, Any]]:
        ref = int(variables_reference)
        if ref == 0:
            return []

        frame_id = self._scope_reference_to_frame.get(ref)
        if frame_id is None:
            # Fallback: allow D2 direct children lookup through all frame stores.
            for thread in self.thread_store.threads():
                frame_store = self.thread_store.frame_store(thread.id)
                try:
                    return frame_store.variable_store.children(ref)
                except KeyError:
                    continue
            raise KeyError(f"unknown scope variablesReference: {ref}")

        frame_store = self._frame_store_for_frame_id(frame_id)
        frame = frame_store.frame(frame_id)
        return frame_store.variable_store.variables(frame.scope_name())

    def assert_scope_contract(self, scope: Dict[str, Any]) -> bool:
        required = {"name", "variablesReference", "expensive"}
        missing = required.difference(scope.keys())
        if missing:
            raise AssertionError(f"scope missing keys: {sorted(missing)}")
        if not isinstance(scope["variablesReference"], int):
            raise AssertionError("scope variablesReference must be int")
        if not isinstance(scope["expensive"], bool):
            raise AssertionError("scope expensive must be bool")
        return True

    def snapshot(self) -> Dict[str, Any]:
        return {
            "scopeFrameCount": len(self._scope_bindings),
            "bindings": {
                str(frame_id): [scope.to_dap() for scope in scopes]
                for frame_id, scopes in self._scope_bindings.items()
            },
        }


class DebugScopeStore(ScopeStore):
    """Public professional alias used by later H4.3 phases."""
    pass
