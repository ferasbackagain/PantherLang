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
