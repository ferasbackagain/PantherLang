import pytest

from debug_adapter.evaluate import EvaluateEngine
from debug_adapter.scopes import ScopeStore
from debug_adapter.threads import ThreadStore
from debug_adapter.watch_expressions import (
    WatchExpressionManager,
    WatchExpressionStore,
    build_watch_manager_for_thread_store,
)
from debug_adapter.variables import WatchExpressionStore as PublicWatchExpressionStore


def _build_watch_store_with_frame():
    threads = ThreadStore()
    main = threads.ensure_main_thread()
    frame = threads.add_frame(
        main.id,
        name="main",
        source_path="examples/hello.pan",
        line=1,
        variables={
            "count": 7,
            "name": "panther",
            "config": {"mode": "debug"},
        },
    )

    scopes = ScopeStore(thread_store=threads)
    engine = EvaluateEngine()
    engine.context.scope_store = scopes

    store = WatchExpressionStore(evaluate_engine=engine)
    return store, threads, scopes, frame


def test_d8_add_and_snapshot_watch_expression():
    store = WatchExpressionStore()

    item = store.add("count", frame_id=1)
    snapshot = store.snapshot()

    assert item.id == 1
    assert item.expression == "count"
    assert snapshot["watchCount"] == 1
    assert snapshot["watchExpressions"][0]["expression"] == "count"
    assert store.assert_watch_contract(snapshot["watchExpressions"][0]) is True


def test_d8_evaluate_watch_against_frame_variable():
    store, threads, scopes, frame = _build_watch_store_with_frame()

    item = store.add("count", frame_id=frame.id)
    result = store.evaluate_one(item.id)

    assert result["result"] == "7"
    assert result["type"] == "int"
    assert result["variablesReference"] == 0
    assert result["metadata"]["watchId"] == item.id

    assert store.get(item.id).last_result == result


def test_d8_evaluate_all_watches():
    store, threads, scopes, frame = _build_watch_store_with_frame()

    store.add("count", frame_id=frame.id)
    store.add("name", frame_id=frame.id)
    store.add('"literal"', frame_id=None)

    results = store.evaluate_all()

    assert len(results) == 3
    assert results[0]["result"] == "7"
    assert results[1]["result"] == "panther"
    assert results[2]["result"] == "literal"


def test_d8_container_watch_preserves_variables_reference():
    store, threads, scopes, frame = _build_watch_store_with_frame()

    item = store.add("config", frame_id=frame.id)
    result = store.evaluate_one(item.id)

    assert result["type"] == "object"
    assert result["variablesReference"] > 0


def test_d8_disabled_watch_is_safe_and_deterministic():
    store, threads, scopes, frame = _build_watch_store_with_frame()

    item = store.add("count", frame_id=frame.id)
    store.disable(item.id)
    result = store.evaluate_one(item.id)

    assert result["result"] == "<disabled>"
    assert result["type"] == "disabled"
    assert result["variablesReference"] == 0
    assert result["metadata"]["enabled"] is False

    store.enable(item.id)
    enabled_result = store.evaluate_one(item.id)
    assert enabled_result["result"] == "7"


def test_d8_update_expression_clears_last_result():
    store, threads, scopes, frame = _build_watch_store_with_frame()

    item = store.add("count", frame_id=frame.id)
    first = store.evaluate_one(item.id)
    assert first["result"] == "7"

    updated = store.update_expression(item.id, "name")

    assert updated.expression == "name"
    assert updated.last_result is None

    second = store.evaluate_one(item.id)
    assert second["result"] == "panther"


def test_d8_remove_and_clear_watches():
    store = WatchExpressionStore()

    first = store.add("a")
    second = store.add("b")

    removed = store.remove(first.id)

    assert removed.id == first.id
    assert len(store.list()) == 1
    assert store.list()[0].id == second.id

    store.clear()
    assert store.snapshot()["watchCount"] == 0


def test_d8_unknown_watch_raises_keyerror():
    store = WatchExpressionStore()

    with pytest.raises(KeyError):
        store.get(404)

    with pytest.raises(KeyError):
        store.evaluate_one(404)


def test_d8_builder_returns_manager():
    threads = ThreadStore()
    manager = build_watch_manager_for_thread_store(threads)

    assert isinstance(manager, WatchExpressionManager)


def test_d8_public_export_exists():
    assert PublicWatchExpressionStore is WatchExpressionStore
