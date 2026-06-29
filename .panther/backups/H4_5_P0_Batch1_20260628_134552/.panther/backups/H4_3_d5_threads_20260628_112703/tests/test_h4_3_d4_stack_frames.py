import pytest

from debug_adapter.stack_frames import DebugStackFrame, StackFrameStore
from debug_adapter.variables import StackFrameStore as PublicStackFrameStore


def test_d4_debug_stack_frame_dap_contract():
    frame = DebugStackFrame(
        id=1,
        name="main",
        source_path="examples/hello.pan",
        line=10,
        column=2,
    )

    payload = frame.to_dap()

    assert payload["id"] == 1
    assert payload["name"] == "main"
    assert payload["source"]["path"] == "examples/hello.pan"
    assert payload["source"]["name"] == "hello.pan"
    assert payload["line"] == 10
    assert payload["column"] == 2


def test_d4_stack_frame_store_create_and_trace_body():
    store = StackFrameStore()

    frame1 = store.create_frame("main", "examples/main.pan", line=1, variables={"x": 1})
    frame2 = store.create_frame("helper", "examples/helper.pan", line=7, variables={"y": 2})

    body = store.stack_trace_body()

    assert body["totalFrames"] == 2
    assert len(body["stackFrames"]) == 2
    assert body["stackFrames"][0]["id"] == frame1.id
    assert body["stackFrames"][1]["id"] == frame2.id

    for frame in body["stackFrames"]:
        assert store.assert_stack_frame_contract(frame) is True


def test_d4_stack_trace_start_and_levels():
    store = StackFrameStore()

    store.create_frame("a", "a.pan", line=1)
    store.create_frame("b", "b.pan", line=2)
    store.create_frame("c", "c.pan", line=3)

    body = store.stack_trace_body(start_frame=1, levels=1)

    assert body["totalFrames"] == 3
    assert len(body["stackFrames"]) == 1
    assert body["stackFrames"][0]["name"] == "b"


def test_d4_frame_variables_integrate_with_d3_store():
    store = StackFrameStore()

    frame = store.create_frame(
        "main",
        "examples/hello.pan",
        line=3,
        variables={
            "count": 7,
            "config": {"mode": "debug"},
        },
    )

    variables = store.variables_for_frame(frame.id)
    by_name = {item["name"]: item for item in variables}

    assert by_name["count"]["value"] == "7"
    assert by_name["count"]["type"] == "int"

    assert by_name["config"]["variablesReference"] > 0
    children = store.variable_store.children(by_name["config"]["variablesReference"])
    assert children[0]["name"] == "mode"
    assert children[0]["value"] == "debug"


def test_d4_set_frame_variable_updates_variable_store():
    store = StackFrameStore()

    frame = store.create_frame("main", "main.pan", variables={"x": 1})
    updated = store.set_frame_variable(frame.id, "x", 99)

    assert updated["name"] == "x"
    assert updated["value"] == "99"

    variables = store.variables_for_frame(frame.id)
    assert {item["name"]: item for item in variables}["x"]["value"] == "99"


def test_d4_pop_and_clear_remove_frame_scopes():
    store = StackFrameStore()

    frame = store.create_frame("main", "main.pan", variables={"x": 1})
    assert store.variable_store.has_scope(frame.scope_name()) is True

    popped = store.pop()
    assert popped.id == frame.id
    assert store.variable_store.has_scope(frame.scope_name()) is False

    frame2 = store.create_frame("main2", "main2.pan", variables={"y": 2})
    assert store.variable_store.has_scope(frame2.scope_name()) is True

    store.clear()
    assert store.frames() == []
    assert store.variable_store.has_scope(frame2.scope_name()) is False


def test_d4_unknown_frame_raises_keyerror():
    store = StackFrameStore()

    with pytest.raises(KeyError):
        store.frame(999)


def test_d4_public_export_exists():
    assert PublicStackFrameStore is StackFrameStore
