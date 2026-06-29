import pytest

from debug_adapter.variable_store import DebugVariableStore, VariableStore
from debug_adapter.variables import VariableStore as PublicVariableStore


def test_d3_create_scope_and_snapshot_contract():
    store = VariableStore()
    store.create_scope("locals", {"x": 1, "name": "panther"})

    snapshot = store.snapshot()

    assert snapshot["scopeCount"] == 1
    assert snapshot["scopes"][0]["name"] == "locals"
    assert store.assert_store_contract() is True


def test_d3_set_and_get_variable():
    store = VariableStore()
    store.create_scope("locals")

    created = store.set_variable("locals", "count", 7)
    fetched = store.get_variable("locals", "count")

    assert created["name"] == "count"
    assert created["value"] == "7"
    assert created["type"] == "int"
    assert fetched == created


def test_d3_variables_returns_dap_payloads():
    store = VariableStore()
    store.create_scope("locals", {
        "count": 7,
        "enabled": True,
        "name": "panther",
    })

    variables = store.variables("locals")
    by_name = {item["name"]: item for item in variables}

    assert by_name["count"]["value"] == "7"
    assert by_name["enabled"]["value"] == "true"
    assert by_name["name"]["type"] == "string"


def test_d3_container_variable_children_work_through_store():
    store = VariableStore()
    store.create_scope("locals", {
        "config": {"mode": "debug", "level": 3},
    })

    variables = store.variables("locals")
    config = variables[0]

    assert config["name"] == "config"
    assert config["variablesReference"] > 0

    children = store.children(config["variablesReference"])
    by_name = {item["name"]: item for item in children}

    assert by_name["mode"]["value"] == "debug"
    assert by_name["level"]["value"] == "3"


def test_d3_unknown_scope_and_variable_raise_keyerror():
    store = VariableStore()

    with pytest.raises(KeyError):
        store.get_scope("missing")

    store.create_scope("locals")

    with pytest.raises(KeyError):
        store.get_variable("locals", "missing")


def test_d3_clear_scope_and_clear_all():
    store = VariableStore()
    store.create_scope("locals", {"x": 1})
    store.create_scope("globals", {"g": 2})

    assert store.snapshot()["scopeCount"] == 2

    store.clear_scope("locals")
    assert store.snapshot()["scopeCount"] == 1
    assert store.has_scope("globals") is True

    store.clear_all()
    assert store.snapshot()["scopeCount"] == 0


def test_d3_public_exports_and_alias():
    assert PublicVariableStore is VariableStore

    store = DebugVariableStore()
    store.create_scope("locals", {"x": 1})

    assert store.variables("locals")[0]["name"] == "x"
