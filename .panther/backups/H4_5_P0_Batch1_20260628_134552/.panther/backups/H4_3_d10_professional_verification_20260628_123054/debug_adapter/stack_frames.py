from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from .variable_store import DebugVariableStore


@dataclass(slots=True)
class StackFrameSource:
    path: str
    name: Optional[str] = None

    def to_dap(self) -> Dict[str, Any]:
        payload = {
            "path": self.path,
            "name": self.name or self.path.split("/")[-1],
        }
        return payload


@dataclass(slots=True)
class DebugStackFrame:
    """
    PantherLang professional DAP stack frame.

    DAP StackFrame fields:
    - id
    - name
    - source
    - line
    - column
    """

    id: int
    name: str
    source_path: str
    line: int = 1
    column: int = 1
    instruction_pointer_reference: Optional[str] = None
    module_id: Optional[str] = None
    presentation_hint: Optional[str] = None
    variables: Dict[str, Any] = field(default_factory=dict)

    def to_dap(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "id": int(self.id),
            "name": str(self.name),
            "source": StackFrameSource(self.source_path).to_dap(),
            "line": int(self.line),
            "column": int(self.column),
        }

        if self.instruction_pointer_reference:
            payload["instructionPointerReference"] = self.instruction_pointer_reference

        if self.module_id:
            payload["moduleId"] = self.module_id

        if self.presentation_hint:
            payload["presentationHint"] = self.presentation_hint

        return payload

    def scope_name(self) -> str:
        return f"frame:{self.id}:locals"


class StackFrameStore:
    """
    H4.3 D4 Stack Frame Store.

    Responsibilities:
    - Maintain ordered call stack frames.
    - Attach frame-local variables using D3 VariableStore.
    - Produce DAP stackTrace response body.
    """

    def __init__(self, variable_store: Optional[DebugVariableStore] = None) -> None:
        self.variable_store = variable_store or DebugVariableStore()
        self._frames: List[DebugStackFrame] = []
        self._next_id = 1

    def create_frame(
        self,
        name: str,
        source_path: str,
        line: int = 1,
        column: int = 1,
        variables: Optional[Dict[str, Any]] = None,
    ) -> DebugStackFrame:
        frame = DebugStackFrame(
            id=self._next_id,
            name=name,
            source_path=source_path,
            line=line,
            column=column,
            variables=dict(variables or {}),
        )
        self._next_id += 1
        self._frames.append(frame)

        self.variable_store.create_scope(frame.scope_name(), frame.variables)
        return frame

    def push(self, frame: DebugStackFrame) -> DebugStackFrame:
        if frame.id <= 0:
            frame.id = self._next_id
            self._next_id += 1
        self._frames.append(frame)
        self.variable_store.create_scope(frame.scope_name(), frame.variables)
        return frame

    def pop(self) -> DebugStackFrame:
        if not self._frames:
            raise IndexError("cannot pop from empty stack frame store")
        frame = self._frames.pop()
        self.variable_store.clear_scope(frame.scope_name())
        return frame

    def clear(self) -> None:
        for frame in list(self._frames):
            self.variable_store.clear_scope(frame.scope_name())
        self._frames.clear()

    def frames(self) -> List[DebugStackFrame]:
        return list(self._frames)

    def frame(self, frame_id: int) -> DebugStackFrame:
        for item in self._frames:
            if item.id == int(frame_id):
                return item
        raise KeyError(f"unknown stack frame id: {frame_id}")

    def dap_frames(self, start_frame: int = 0, levels: Optional[int] = None) -> List[Dict[str, Any]]:
        selected = self._frames[int(start_frame):]
        if levels is not None:
            selected = selected[: int(levels)]
        return [frame.to_dap() for frame in selected]

    def stack_trace_body(self, start_frame: int = 0, levels: Optional[int] = None) -> Dict[str, Any]:
        frames = self.dap_frames(start_frame=start_frame, levels=levels)
        return {
            "stackFrames": frames,
            "totalFrames": len(self._frames),
        }

    def variables_for_frame(self, frame_id: int) -> List[Dict[str, Any]]:
        frame = self.frame(frame_id)
        return self.variable_store.variables(frame.scope_name())

    def set_frame_variable(self, frame_id: int, name: str, value: Any) -> Dict[str, Any]:
        frame = self.frame(frame_id)
        frame.variables[str(name)] = value
        return self.variable_store.set_variable(frame.scope_name(), str(name), value)

    def assert_stack_frame_contract(self, frame: Dict[str, Any]) -> bool:
        required = {"id", "name", "source", "line", "column"}
        missing = required.difference(frame.keys())
        if missing:
            raise AssertionError(f"stack frame missing keys: {sorted(missing)}")
        if not isinstance(frame["id"], int):
            raise AssertionError("stack frame id must be int")
        if not isinstance(frame["line"], int):
            raise AssertionError("stack frame line must be int")
        if not isinstance(frame["column"], int):
            raise AssertionError("stack frame column must be int")
        return True
