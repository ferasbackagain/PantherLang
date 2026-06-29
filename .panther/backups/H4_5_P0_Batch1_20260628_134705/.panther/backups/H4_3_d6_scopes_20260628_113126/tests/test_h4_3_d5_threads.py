import pytest

from debug_adapter.threads import DebugThread, ThreadStore
from debug_adapter.variables import ThreadStore as PublicThreadStore


def test_d5_debug_thread_dap_contract():
    thread = DebugThread(id=1, name="Main Thread", state="running")

    payload = thread.to_dap()

    assert payload["id"] == 1
    assert payload["name"] == "Main Thread"
    assert "state" not in payload


def test_d5_thread_store_create_and_threads_body():
    store = ThreadStore()

    main = store.create_thread("Main Thread")
    worker = store.create_thread("Worker Thread", state="paused")

    body = store.threads_body()

    assert body["threads"][0]["id"] == main.id
    assert body["threads"][0]["name"] == "Main Thread"
    assert body["threads"][1]["id"] == worker.id
    assert body["threads"][1]["name"] == "Worker Thread"

    for thread in body["threads"]:
        assert store.assert_thread_contract(thread) is True


def test_d5_ensure_main_thread_is_deterministic():
    store = ThreadStore()

    main1 = store.ensure_main_thread()
    main2 = store.ensure_main_thread()

    assert main1.id == 1
    assert main2.id == 1
    assert main1 is main2
    assert store.snapshot()["threadCount"] == 1


def test_d5_thread_stack_frames_integrate_with_d4():
    store = ThreadStore()
    main = store.ensure_main_thread()

    frame = store.add_frame(
        main.id,
        name="main",
        source_path="examples/hello.pan",
        line=4,
        variables={"x": 1},
    )

    trace = store.stack_trace_body(main.id)

    assert trace["totalFrames"] == 1
    assert trace["stackFrames"][0]["id"] == frame.id
    assert trace["stackFrames"][0]["name"] == "main"
    assert trace["stackFrames"][0]["line"] == 4


def test_d5_thread_frame_variables_integrate_with_d3():
    store = ThreadStore()
    main = store.ensure_main_thread()

    frame = store.add_frame(
        main.id,
        name="main",
        source_path="examples/hello.pan",
        line=1,
        variables={"config": {"mode": "debug"}},
    )

    frame_store = store.frame_store(main.id)
    variables = frame_store.variables_for_frame(frame.id)

    config = variables[0]

    assert config["name"] == "config"
    assert config["variablesReference"] > 0

    children = frame_store.variable_store.children(config["variablesReference"])
    assert children[0]["name"] == "mode"
    assert children[0]["value"] == "debug"


def test_d5_set_thread_state_and_snapshot():
    store = ThreadStore()
    main = store.ensure_main_thread()

    store.set_thread_state(main.id, "paused")
    snapshot = store.snapshot()

    assert snapshot["threadCount"] == 1
    assert snapshot["threads"][0]["state"] == "paused"


def test_d5_remove_and_clear_threads():
    store = ThreadStore()
    main = store.ensure_main_thread()
    worker = store.create_thread("Worker")

    removed = store.remove_thread(worker.id)

    assert removed.id == worker.id
    assert store.has_thread(main.id) is True
    assert store.has_thread(worker.id) is False

    store.clear()
    assert store.snapshot()["threadCount"] == 0


def test_d5_unknown_thread_raises_keyerror():
    store = ThreadStore()

    with pytest.raises(KeyError):
        store.get_thread(999)

    with pytest.raises(KeyError):
        store.frame_store(999)

    with pytest.raises(KeyError):
        store.stack_trace_body(999)


def test_d5_public_export_exists():
    assert PublicThreadStore is ThreadStore
