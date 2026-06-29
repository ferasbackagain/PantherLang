import pytest

from debug_adapter.scopes import DebugScope, ScopeStore
from debug_adapter.threads import ThreadStore
from debug_adapter.variables import ScopeStore as PublicScopeStore


def _build_scope_store_with_frame():
    threads = ThreadStore()
    main = threads.ensure_main_thread()
    frame = threads.add_frame(
        main.id,
        name="main",
        source_path="examples/hello.pan",
        line=12,
        column=3,
        variables={
            "count": 7,
            "config": {"mode": "debug"},
        },
    )
    scopes = ScopeStore(thread_store=threads)
    return threads, scopes, frame


def test_d6_debug_scope_dap_contract():
    scope = DebugScope(
        name="Locals",
        variables_reference=1000,
        expensive=False,
        named_variables=2,
    )

    payload = scope.to_dap()

    assert payload["name"] == "Locals"
    assert payload["variablesReference"] == 1000
    assert payload["expensive"] is False
    assert payload["namedVariables"] == 2


def test_d6_create_local_scope_for_frame():
    threads, scopes, frame = _build_scope_store_with_frame()

    scope = scopes.create_local_scope_for_frame(frame.id)
    payload = scope.to_dap()

    assert payload["name"] == "Locals"
    assert payload["variablesReference"] > 0
    assert payload["expensive"] is False
    assert payload["namedVariables"] == 2
    assert payload["source"]["path"] == "examples/hello.pan"
    assert payload["line"] == 12
    assert payload["column"] == 3
    assert scopes.assert_scope_contract(payload) is True


def test_d6_scopes_body_returns_dap_scopes_response_body():
    threads, scopes, frame = _build_scope_store_with_frame()

    body = scopes.scopes_body(frame.id)

    assert "scopes" in body
    assert len(body["scopes"]) == 1
    assert body["scopes"][0]["name"] == "Locals"
    assert body["scopes"][0]["variablesReference"] > 0


def test_d6_variables_for_scope_reference_returns_frame_variables():
    threads, scopes, frame = _build_scope_store_with_frame()

    body = scopes.scopes_body(frame.id)
    ref = body["scopes"][0]["variablesReference"]

    variables = scopes.variables_for_scope_reference(ref)
    by_name = {item["name"]: item for item in variables}

    assert by_name["count"]["value"] == "7"
    assert by_name["count"]["type"] == "int"
    assert by_name["config"]["variablesReference"] > 0


def test_d6_empty_scope_has_zero_reference():
    threads = ThreadStore()
    main = threads.ensure_main_thread()
    frame = threads.add_frame(
        main.id,
        name="empty",
        source_path="empty.pan",
        variables={},
    )
    scopes = ScopeStore(thread_store=threads)

    scope = scopes.create_empty_scope(frame.id)
    payload = scope.to_dap()

    assert payload["name"] == "Locals"
    assert payload["variablesReference"] == 0
    assert scopes.variables_for_scope_reference(0) == []


def test_d6_scopes_for_frame_is_idempotent():
    threads, scopes, frame = _build_scope_store_with_frame()

    first = scopes.scopes_for_frame(frame.id)
    second = scopes.scopes_for_frame(frame.id)

    assert len(first) == 1
    assert len(second) == 1
    assert first[0].variables_reference == second[0].variables_reference


def test_d6_unknown_frame_raises_keyerror():
    scopes = ScopeStore(thread_store=ThreadStore())

    with pytest.raises(KeyError):
        scopes.scopes_body(999)


def test_d6_snapshot_contract():
    threads, scopes, frame = _build_scope_store_with_frame()
    scopes.scopes_body(frame.id)

    snapshot = scopes.snapshot()

    assert snapshot["scopeFrameCount"] == 1
    assert str(frame.id) in snapshot["bindings"]


def test_d6_public_export_exists():
    assert PublicScopeStore is ScopeStore
