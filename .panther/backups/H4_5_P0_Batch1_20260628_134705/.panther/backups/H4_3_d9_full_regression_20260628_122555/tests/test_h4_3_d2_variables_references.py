import pytest

from debug_adapter.variable_references import (
    VariableReferenceAllocator,
    VariableReferenceResolver,
    VariableReferenceService,
)
from debug_adapter.variables import VariableReferenceService as PublicVariableReferenceService


def test_d2_allocator_assigns_deterministic_positive_references():
    allocator = VariableReferenceAllocator(start=200)

    first = allocator.allocate("config", {"mode": "debug"})
    second = allocator.allocate("items", [1, 2, 3], parent_reference=first)

    assert first == 200
    assert second == 201
    assert allocator.has(first) is True
    assert allocator.has(second) is True
    assert allocator.get(second).parent_reference == first
    assert allocator.count() == 2


def test_d2_allocator_rejects_unknown_reference():
    allocator = VariableReferenceAllocator()

    with pytest.raises(KeyError):
        allocator.get(404)


def test_d2_resolver_expands_dict_children():
    resolver = VariableReferenceResolver()

    children = resolver.children_for("config", {"mode": "debug", "level": 3})

    assert [child.name for child in children] == ["mode", "level"]
    assert children[0].evaluate_name == "config.mode"
    assert children[1].evaluate_name == "config.level"


def test_d2_resolver_expands_array_children():
    resolver = VariableReferenceResolver()

    children = resolver.children_for("items", ["a", "b"])

    assert [child.name for child in children] == ["0", "1"]
    assert children[0].evaluate_name == "items[0]"
    assert children[1].evaluate_name == "items[1]"


def test_d2_reference_service_assigns_refs_to_containers_only():
    service = VariableReferenceService()

    variables = service.variables_from_mapping({
        "count": 7,
        "name": "panther",
        "items": [1, 2],
        "config": {"mode": "debug"},
    })

    by_name = {item["name"]: item for item in variables}

    assert by_name["count"]["variablesReference"] == 0
    assert by_name["name"]["variablesReference"] == 0
    assert by_name["items"]["variablesReference"] > 0
    assert by_name["config"]["variablesReference"] > 0

    for item in variables:
        assert service.assert_reference_contract(item) is True


def test_d2_children_resolution_from_reference():
    service = VariableReferenceService()

    root = service.variable("config", {"mode": "debug", "level": 3})
    ref = root["variablesReference"]

    assert ref > 0

    children = service.children(ref)
    by_name = {item["name"]: item for item in children}

    assert by_name["mode"]["value"] == "debug"
    assert by_name["mode"]["type"] == "string"
    assert by_name["level"]["value"] == "3"
    assert by_name["level"]["type"] == "int"


def test_d2_nested_reference_allocation():
    service = VariableReferenceService()

    root = service.variable("root", {"nested": {"x": 1}})
    root_ref = root["variablesReference"]

    children = service.children(root_ref)
    nested = children[0]

    assert nested["name"] == "nested"
    assert nested["variablesReference"] > 0

    nested_children = service.children(nested["variablesReference"])
    assert nested_children[0]["name"] == "x"
    assert nested_children[0]["value"] == "1"


def test_d2_public_variables_module_exports_reference_service():
    assert PublicVariableReferenceService is VariableReferenceService
