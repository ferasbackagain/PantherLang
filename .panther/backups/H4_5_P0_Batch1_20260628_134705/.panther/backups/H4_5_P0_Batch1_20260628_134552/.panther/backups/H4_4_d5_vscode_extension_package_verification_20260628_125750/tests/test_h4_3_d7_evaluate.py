from debug_adapter.evaluate import EvaluateEngine, EvaluateResult
from debug_adapter.scopes import ScopeStore
from debug_adapter.threads import ThreadStore
from debug_adapter.variables import EvaluateEngine as PublicEvaluateEngine


def _build_evaluate_engine_with_frame():
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
            "enabled": True,
            "config": {"mode": "debug"},
        },
    )
    scopes = ScopeStore(thread_store=threads)
    engine = EvaluateEngine()
    engine.context.scope_store = scopes
    return engine, scopes, frame


def test_d7_evaluate_result_contract():
    result = EvaluateResult(
        result="7",
        type_name="int",
        variables_reference=0,
    )

    body = result.to_dap_body()

    assert body["result"] == "7"
    assert body["type"] == "int"
    assert body["variablesReference"] == 0


def test_d7_literal_evaluation_contracts():
    engine = EvaluateEngine()

    samples = [
        ("7", "int", "7"),
        ("3.14", "float", "3.14"),
        ("true", "bool", "true"),
        ("false", "bool", "false"),
        ("null", "null", "null"),
        ('"hello"', "string", "hello"),
    ]

    for expression, expected_type, expected_result in samples:
        body = engine.evaluate_body(expression)
        assert body["type"] == expected_type
        assert body["result"] == expected_result
        assert body["variablesReference"] == 0
        assert engine.assert_evaluate_body_contract(body) is True


def test_d7_frame_variable_lookup():
    engine, scopes, frame = _build_evaluate_engine_with_frame()

    body = engine.evaluate_body("count", frame_id=frame.id)

    assert body["result"] == "7"
    assert body["type"] == "int"
    assert body["variablesReference"] == 0
    assert body["metadata"]["source"] == "variable"
    assert body["metadata"]["name"] == "count"


def test_d7_frame_string_and_bool_variable_lookup():
    engine, scopes, frame = _build_evaluate_engine_with_frame()

    name = engine.evaluate_body("name", frame_id=frame.id)
    enabled = engine.evaluate_body("enabled", frame_id=frame.id)

    assert name["result"] == "panther"
    assert name["type"] == "string"

    assert enabled["result"] == "true"
    assert enabled["type"] == "bool"


def test_d7_container_variable_lookup_returns_reference():
    engine, scopes, frame = _build_evaluate_engine_with_frame()

    body = engine.evaluate_body("config", frame_id=frame.id)

    assert body["result"] == "{'mode': 'debug'}"
    assert body["type"] == "object"
    assert body["variablesReference"] > 0


def test_d7_variables_reference_lookup():
    engine, scopes, frame = _build_evaluate_engine_with_frame()

    scope_body = scopes.scopes_body(frame.id)
    scope_ref = scope_body["scopes"][0]["variablesReference"]

    body = engine.evaluate_body("count", variables_reference=scope_ref)

    assert body["result"] == "7"
    assert body["type"] == "int"


def test_d7_unresolved_expression_is_safe_and_deterministic():
    engine, scopes, frame = _build_evaluate_engine_with_frame()

    body = engine.evaluate_body("does_not_exist", frame_id=frame.id)

    assert body["result"] == "<unresolved: does_not_exist>"
    assert body["type"] == "unresolved"
    assert body["variablesReference"] == 0


def test_d7_synthetic_expression_without_frame_does_not_execute_code():
    engine = EvaluateEngine()

    body = engine.evaluate_body("__import__('os').system('echo bad')")

    assert body["type"] == "expression"
    assert body["result"].startswith("<expression:")
    assert body["variablesReference"] == 0


def test_d7_empty_expression_contract():
    engine = EvaluateEngine()

    body = engine.evaluate_body("")

    assert body["result"] == ""
    assert body["type"] == "string"
    assert body["variablesReference"] == 0
    assert body["metadata"]["empty"] is True


def test_d7_public_export_exists():
    assert PublicEvaluateEngine is EvaluateEngine
