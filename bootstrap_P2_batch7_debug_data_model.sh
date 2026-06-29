#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-2"
echo " Canonical Debug Adapter Rebuild"
echo " Batch 7 - Debug Data Model"
echo "============================================================"

ROOT="$(pwd)"
P2="$ROOT/.panther/p2_debug_adapter_rebuild"
REBUILT="$ROOT/debug_adapter_rebuilt"
REPORTS="$ROOT/reports/P2"
TESTS="$ROOT/tests/P2_canonical_debug_adapter"

mkdir -p "$REBUILT" "$REPORTS" "$TESTS"

[ -f "$P2/status_batch6.json" ] || { echo "[P2-B7][ERROR] Run Batch 6 first."; exit 1; }

cat > "$REBUILT/variables_core.py" <<'PY'
from dataclasses import dataclass
from typing import Any

@dataclass
class DebugVariable:
    name: str
    value: str
    type: str = "string"
    variablesReference: int = 0

class VariableFactory:
    @staticmethod
    def from_value(name: str, value: Any):
        if isinstance(value, bool):
            t = "boolean"
        elif isinstance(value, int):
            t = "number"
        elif isinstance(value, float):
            t = "number"
        elif isinstance(value, (dict, list, tuple)):
            t = "object"
        else:
            t = "string"
        return DebugVariable(name=name, value=str(value), type=t)

class VariablesCore:
    def make(self, name: str, value: Any):
        return VariableFactory.from_value(name, value)
PY

cat > "$REBUILT/variable_references.py" <<'PY'
class VariableReferenceAllocator:
    def __init__(self):
        self._next = 1
        self._objects = {}

    def allocate(self, value):
        ref = self._next
        self._next += 1
        self._objects[ref] = value
        return ref

    def get(self, ref):
        return self._objects.get(ref)

    def has(self, ref):
        return ref in self._objects
PY

cat > "$REBUILT/variable_store.py" <<'PY'
from .variables_core import VariableFactory
from .variable_references import VariableReferenceAllocator

class DebugVariableStore:
    def __init__(self):
        self.refs = VariableReferenceAllocator()
        self.globals = {}

    def set(self, name, value):
        self.globals[name] = value
        return self.get(name)

    def get(self, name):
        value = self.globals[name]
        var = VariableFactory.from_value(name, value)
        if isinstance(value, (dict, list, tuple)):
            var.variablesReference = self.refs.allocate(value)
        return var

    def variables(self):
        return [self.get(k) for k in sorted(self.globals)]

class VariableStore(DebugVariableStore):
    pass
PY

cat > "$REBUILT/stack_frames.py" <<'PY'
from dataclasses import dataclass

@dataclass
class DebugStackFrame:
    id: int
    name: str
    line: int
    column: int = 1
    source: dict | None = None

class StackFrameStore:
    def __init__(self):
        self._frames = []

    def push(self, name, line=1, source_path="main.pan"):
        frame = DebugStackFrame(
            id=len(self._frames)+1,
            name=name,
            line=line,
            source={"path": source_path},
        )
        self._frames.append(frame)
        return frame

    def list(self):
        return list(self._frames)

    def clear(self):
        self._frames.clear()
PY

cat > "$REBUILT/threads.py" <<'PY'
from dataclasses import dataclass

@dataclass
class DebugThread:
    id: int
    name: str

class ThreadStore:
    def __init__(self):
        self._threads = [DebugThread(1, "main")]

    def list(self):
        return list(self._threads)

    def main(self):
        return self._threads[0]
PY

cat > "$REBUILT/scopes.py" <<'PY'
from dataclasses import dataclass

@dataclass
class DebugScope:
    name: str
    variablesReference: int
    expensive: bool = False

class ScopeStore:
    def __init__(self):
        self._scopes = []

    def add(self, name, variablesReference, expensive=False):
        scope = DebugScope(name, variablesReference, expensive)
        self._scopes.append(scope)
        return scope

    def list(self):
        return list(self._scopes)
PY

cat > "$REBUILT/evaluate.py" <<'PY'
from dataclasses import dataclass

@dataclass
class EvaluateResult:
    result: str
    type: str = "string"
    variablesReference: int = 0

class EvaluateEngine:
    def __init__(self, variables=None):
        self.variables = variables or {}

    def evaluate(self, expression):
        if expression in self.variables:
            value = self.variables[expression]
            return EvaluateResult(result=str(value), type=type(value).__name__)
        try:
            value = eval(expression, {"__builtins__": {}}, dict(self.variables))
            return EvaluateResult(result=str(value), type=type(value).__name__)
        except Exception as exc:
            return EvaluateResult(result=f"error: {exc}", type="error")
PY

cat > "$REBUILT/watch_expressions.py" <<'PY'
class WatchExpressionStore:
    def __init__(self):
        self._items = []

    def add(self, expression):
        if expression not in self._items:
            self._items.append(expression)
        return expression

    def remove(self, expression):
        if expression in self._items:
            self._items.remove(expression)

    def list(self):
        return list(self._items)
PY

cat > "$TESTS/test_p2_batch7_data_model.py" <<'PY'
from debug_adapter_rebuilt.variables_core import DebugVariable, VariableFactory, VariablesCore
from debug_adapter_rebuilt.variable_references import VariableReferenceAllocator
from debug_adapter_rebuilt.variable_store import DebugVariableStore, VariableStore
from debug_adapter_rebuilt.stack_frames import DebugStackFrame, StackFrameStore
from debug_adapter_rebuilt.threads import DebugThread, ThreadStore
from debug_adapter_rebuilt.scopes import DebugScope, ScopeStore
from debug_adapter_rebuilt.evaluate import EvaluateEngine, EvaluateResult
from debug_adapter_rebuilt.watch_expressions import WatchExpressionStore


def test_variables_core_and_store():
    v = VariableFactory.from_value("x", 7)
    assert v.name == "x"
    assert v.value == "7"
    assert v.type == "number"

    store = VariableStore()
    store.set("a", 1)
    store.set("obj", {"k": "v"})
    values = store.variables()
    assert [x.name for x in values] == ["a", "obj"]
    assert values[1].variablesReference > 0


def test_references_stack_threads_scopes():
    refs = VariableReferenceAllocator()
    ref = refs.allocate({"hello": "world"})
    assert refs.has(ref)
    assert refs.get(ref)["hello"] == "world"

    frames = StackFrameStore()
    f = frames.push("main", line=3)
    assert f.id == 1
    assert f.source["path"] == "main.pan"

    threads = ThreadStore()
    assert threads.main().name == "main"
    assert threads.list()[0].id == 1

    scopes = ScopeStore()
    s = scopes.add("Locals", variablesReference=ref)
    assert s.name == "Locals"
    assert scopes.list()[0].variablesReference == ref


def test_evaluate_and_watch_expressions():
    engine = EvaluateEngine({"x": 2, "y": 3})
    assert engine.evaluate("x").result == "2"
    assert engine.evaluate("x + y").result == "5"

    watch = WatchExpressionStore()
    watch.add("x")
    watch.add("x")
    watch.add("y")
    assert watch.list() == ["x", "y"]
    watch.remove("x")
    assert watch.list() == ["y"]
PY

python3 -m py_compile \
  "$REBUILT/variables_core.py" \
  "$REBUILT/variable_references.py" \
  "$REBUILT/variable_store.py" \
  "$REBUILT/stack_frames.py" \
  "$REBUILT/threads.py" \
  "$REBUILT/scopes.py" \
  "$REBUILT/evaluate.py" \
  "$REBUILT/watch_expressions.py" \
  "$TESTS/test_p2_batch7_data_model.py"

python3 -m pytest "$TESTS/test_p2_batch7_data_model.py" -q

cat > "$REPORTS/P2_BATCH7_DEBUG_DATA_MODEL.md" <<'EOF'
# P-2 Batch 7 - Debug Data Model

Status: PASSED

Implemented:
- Variables core
- Variable references
- Variable store
- Stack frames
- Threads
- Scopes
- Evaluate engine
- Watch expressions

Runtime Modification:
None. Existing debug_adapter/ was not modified.

Next:
P-2 Batch 8 - Integration Regression.
EOF

cat > "$P2/status_batch7.json" <<'EOF'
{
  "ok": true,
  "phase": "P-2",
  "batch": "7",
  "status": "PASSED",
  "runtime_modified": false,
  "next": "P-2 Batch 8 - Integration Regression"
}
EOF

echo "============================================================"
echo "✅ P-2 Batch 7 COMPLETE"
echo "Next: P-2 Batch 8 - Integration Regression"
echo "============================================================"
