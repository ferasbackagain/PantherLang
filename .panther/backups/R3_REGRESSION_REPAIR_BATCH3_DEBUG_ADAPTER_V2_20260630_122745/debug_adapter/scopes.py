from dataclasses import dataclass
from .threads import ThreadStore

@dataclass
class DebugScope:
    name: str
    variables_reference: int
    expensive: bool = False
    named_variables: int = 0
    source: dict | None = None
    line: int = 1
    column: int = 1

    def to_dap(self):
        data = {
            "name": self.name,
            "variablesReference": self.variables_reference,
            "expensive": self.expensive,
            "namedVariables": self.named_variables,
        }
        if self.source is not None:
            data["source"] = self.source
            data["line"] = self.line
            data["column"] = self.column
        return data

class ScopeStore:
    def __init__(self, thread_store=None):
        self.thread_store = thread_store or ThreadStore()
        self._bindings = {}

    def _find_frame_store_and_frame(self, frame_id):
        for thread in self.thread_store.list():
            store = self.thread_store.frame_store(thread.id)
            try:
                return store, store.frame(frame_id)
            except KeyError:
                pass
        raise KeyError(frame_id)

    def create_local_scope_for_frame(self, frame_id):
        store, frame = self._find_frame_store_and_frame(frame_id)
        ref = store.variable_store.service.allocator.allocate(frame.scope_name(), frame.variables) if frame.variables else 0
        self._bindings[frame.id] = ref
        return DebugScope("Locals", ref, False, len(frame.variables), {"path": frame.source_path}, frame.line, frame.column)

    def scopes_for_frame(self, frame_id):
        if frame_id not in self._bindings:
            return [self.create_local_scope_for_frame(frame_id)]
        store, frame = self._find_frame_store_and_frame(frame_id)
        return [DebugScope("Locals", self._bindings[frame.id], False, len(frame.variables), {"path": frame.source_path}, frame.line, frame.column)]

    def scopes_body(self, frame_id):
        return {"scopes": [s.to_dap() for s in self.scopes_for_frame(frame_id)]}

    def variables_for_scope_reference(self, ref):
        for thread in self.thread_store.list():
            store = self.thread_store.frame_store(thread.id)
            try:
                return store.variable_store.children(ref)
            except Exception:
                pass
        return []

    def variables_for_frame(self, frame_id):
        store, frame = self._find_frame_store_and_frame(frame_id)
        return store.variables_for_frame(frame.id)

    def snapshot(self):
        return {"scopeFrameCount": len(self._bindings), "bindings": {str(k): v for k, v in self._bindings.items()}}

    def assert_scope_contract(self, item):
        return isinstance(item, dict) and {"name", "variablesReference", "expensive"} <= set(item)
