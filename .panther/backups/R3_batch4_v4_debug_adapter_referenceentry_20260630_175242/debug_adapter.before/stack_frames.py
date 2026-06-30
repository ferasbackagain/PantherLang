from dataclasses import dataclass, field
from pathlib import Path
from typing import Any
from .variable_references import VariableReferenceService

@dataclass
class DebugStackFrame:
    id: int
    name: str
    source_path: str = "main.pan"
    line: int = 1
    column: int = 1
    variables: dict[str, Any] = field(default_factory=dict)

    def scope_name(self):
        return f"frame:{self.id}:locals"

    def to_dap(self):
        return {
            "id": self.id,
            "name": self.name,
            "source": {"path": self.source_path, "name": Path(self.source_path).name},
            "line": self.line,
            "column": self.column,
        }

class _FrameVariableStore:
    def __init__(self):
        self.service = VariableReferenceService()
        self._scopes = {}

    def set_scope(self, name, variables):
        self._scopes[name] = dict(variables or {})

    def remove_scope(self, name):
        self._scopes.pop(name, None)

    def variables(self, name):
        return self.service.variables_from_mapping(self._scopes.get(name, {}))

    def children(self, ref):
        return self.service.children(ref)

    def set_variable(self, scope, name, value):
        self._scopes.setdefault(scope, {})[name] = value
        return self.service.variable(name, value)

class StackFrameStore:
    def __init__(self):
        self._frames = []
        self._next = 1
        self.variable_store = _FrameVariableStore()

    def create_frame(self, name, source_path="main.pan", line=1, column=1, variables=None):
        frame = DebugStackFrame(self._next, name, source_path, line, column, dict(variables or {}))
        self._next += 1
        self._frames.append(frame)
        self.variable_store.set_scope(frame.scope_name(), frame.variables)
        return frame

    def push(self, name, line=1, source_path="main.pan", variables=None):
        return self.create_frame(name, source_path, line, 1, variables)

    def frames(self):
        return list(self._frames)

    def list(self):
        return self.frames()

    def frame(self, frame_id):
        for frame in self._frames:
            if frame.id == frame_id:
                return frame
        raise KeyError(frame_id)

    def stack_trace_body(self, start_frame=0, levels=None):
        frames = self._frames[start_frame:]
        if levels is not None:
            frames = frames[:levels]
        return {"stackFrames": [f.to_dap() for f in frames], "totalFrames": len(self._frames)}

    def variables_for_frame(self, frame_id):
        return self.variable_store.variables(self.frame(frame_id).scope_name())

    def set_frame_variable(self, frame_id, name, value):
        frame = self.frame(frame_id)
        frame.variables[name] = value
        return self.variable_store.set_variable(frame.scope_name(), name, value)

    def pop(self):
        frame = self._frames.pop()
        self.variable_store.remove_scope(frame.scope_name())
        return frame

    def clear(self):
        for frame in self._frames:
            self.variable_store.remove_scope(frame.scope_name())
        self._frames.clear()

    def assert_stack_frame_contract(self, item):
        return isinstance(item, dict) and {"id", "name", "source", "line", "column"} <= set(item)
