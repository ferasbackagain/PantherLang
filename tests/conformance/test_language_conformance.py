"""Verify every documented language feature has a runnable conformance example."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONF = ROOT / "examples" / "conformance"

FEATURE_EXAMPLES = {
    "literals": "01_literals.pan",
    "variables": "02_variables.pan",
    "assignment": "03_assignment.pan",
    "compound_assignment": "04_compound_assignment.pan",
    "arrays": "05_arrays_objects_indexing.pan",
    "objects": "05_arrays_objects_indexing.pan",
    "indexing": "05_arrays_objects_indexing.pan",
    "expressions": "06_expressions_operators.pan",
    "operators": "06_expressions_operators.pan",
    "functions": "07_functions.pan",
    "recursion": "08_recursion.pan",
    "control_flow": "09_control_flow.pan",
    "loops": "10_loops.pan",
    "structs": "11_structs.pan",
}


def test_all_conformance_examples_exist():
    expected = [
        "01_literals.pan",
        "02_variables.pan",
        "03_assignment.pan",
        "04_compound_assignment.pan",
        "05_arrays_objects_indexing.pan",
        "06_expressions_operators.pan",
        "07_functions.pan",
        "08_recursion.pan",
        "09_control_flow.pan",
        "10_loops.pan",
        "11_structs.pan",
        "12_stdlib_string_math_json.pan",
        "13_filesystem.pan",
        "14_sqlite_crud.pan",
        "15_http_client.pan",
        "16_security_audit.pan",
        "17_ai_mock.pan",
    ]
    for name in expected:
        assert (CONF / name).exists(), f"Missing conformance example: {name}"


def test_conformance_examples_run():
    from cli.panther_cli import main
    for name in sorted(CONF.iterdir()):
        if name.suffix == ".pan":
            result = main(["run", str(name)])
            assert result == 0, f"Conformance example {name.name} failed"


def test_every_feature_has_example():
    for feature, filename in FEATURE_EXAMPLES.items():
        assert (CONF / filename).exists(), f"No example for feature: {feature}"
