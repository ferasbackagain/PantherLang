from debug_adapter.variables_core import DebugVariable, VariableFactory, VariablesCore


def test_d1_debug_variable_scalar_contracts():
    samples = [
        ("count", 7, "int", "7"),
        ("ratio", 3.14, "float", "3.14"),
        ("name", "panther", "string", "panther"),
        ("enabled", True, "bool", "true"),
        ("missing", None, "null", "null"),
    ]

    for name, value, type_name, expected_value in samples:
        variable = DebugVariable(name=name, value=value).to_dap()

        assert variable["name"] == name
        assert variable["value"] == expected_value
        assert variable["type"] == type_name
        assert variable["variablesReference"] == 0


def test_d1_debug_variable_container_detection_without_reference_allocation():
    array_var = DebugVariable(name="items", value=[1, 2, 3])
    object_var = DebugVariable(name="config", value={"mode": "debug"})

    assert array_var.type_name == "array"
    assert object_var.type_name == "object"
    assert array_var.has_children is True
    assert object_var.has_children is True
    assert array_var.to_dap()["variablesReference"] == 0
    assert object_var.to_dap()["variablesReference"] == 0


def test_d1_variable_factory_from_mapping():
    factory = VariableFactory()
    variables = factory.from_mapping({
        "a": 1,
        "b": "two",
        "c": False,
    })

    payloads = [item.to_dap() for item in variables]

    assert [item["name"] for item in payloads] == ["a", "b", "c"]
    assert payloads[0]["type"] == "int"
    assert payloads[1]["type"] == "string"
    assert payloads[2]["type"] == "bool"
    assert payloads[2]["value"] == "false"


def test_d1_variable_factory_from_iterable():
    factory = VariableFactory()
    variables = factory.from_iterable([10, 20], prefix="arg")
    payloads = [item.to_dap() for item in variables]

    assert payloads[0]["name"] == "arg0"
    assert payloads[0]["evaluateName"] == "arg0"
    assert payloads[0]["value"] == "10"
    assert payloads[1]["name"] == "arg1"
    assert payloads[1]["value"] == "20"


def test_d1_variables_core_facade_contract():
    core = VariablesCore()

    variable = core.variable("total", 99, evaluate_name="total")
    assert variable["name"] == "total"
    assert variable["value"] == "99"
    assert variable["type"] == "int"
    assert variable["variablesReference"] == 0
    assert core.assert_variable_contract(variable) is True

    mapping = core.variables_from_mapping({"x": 1, "y": "yes"})
    assert len(mapping) == 2
    for item in mapping:
        assert core.assert_variable_contract(item) is True


def test_d1_variables_module_public_imports():
    from debug_adapter.variables import DebugVariable as ImportedDebugVariable
    from debug_adapter.variables import VariableFactory as ImportedVariableFactory
    from debug_adapter.variables import VariablesCore as ImportedVariablesCore

    assert ImportedDebugVariable is DebugVariable
    assert ImportedVariableFactory is VariableFactory
    assert ImportedVariablesCore is VariablesCore
