from debug_adapter.threads import ThreadStore
from debug_adapter.scopes import ScopeStore
from debug_adapter.evaluate import EvaluateEngine
from debug_adapter.watch_expressions import WatchExpressionStore


def test_d9_integrated_thread_frame_scope_variable_evaluate_watch_flow():
    threads = ThreadStore()
    main = threads.ensure_main_thread()

    frame = threads.add_frame(
        main.id,
        name="main",
        source_path="examples/hello.pan",
        line=11,
        column=1,
        variables={
            "count": 7,
            "name": "panther",
            "config": {"mode": "debug", "level": 3},
        },
    )

    trace = threads.stack_trace_body(main.id)
    assert trace["totalFrames"] == 1
    assert trace["stackFrames"][0]["name"] == "main"
    assert trace["stackFrames"][0]["line"] == 11

    scopes = ScopeStore(thread_store=threads)
    scopes_body = scopes.scopes_body(frame.id)

    assert len(scopes_body["scopes"]) == 1
    scope = scopes_body["scopes"][0]

    assert scope["name"] == "Locals"
    assert scope["variablesReference"] > 0
    assert scope["namedVariables"] == 3

    variables = scopes.variables_for_scope_reference(scope["variablesReference"])
    by_name = {item["name"]: item for item in variables}

    assert by_name["count"]["value"] == "7"
    assert by_name["name"]["value"] == "panther"
    assert by_name["config"]["type"] == "object"
    assert by_name["config"]["variablesReference"] > 0

    evaluate = EvaluateEngine()
    evaluate.context.scope_store = scopes

    count_eval = evaluate.evaluate_body("count", frame_id=frame.id)
    assert count_eval["result"] == "7"
    assert count_eval["type"] == "int"

    config_eval = evaluate.evaluate_body("config", frame_id=frame.id)
    assert config_eval["type"] == "object"
    assert config_eval["variablesReference"] > 0

    watch = WatchExpressionStore(evaluate_engine=evaluate)
    watch.add("count", frame_id=frame.id)
    watch.add("name", frame_id=frame.id)
    watch.add("config", frame_id=frame.id)

    results = watch.evaluate_all()

    assert len(results) == 3
    assert results[0]["result"] == "7"
    assert results[1]["result"] == "panther"
    assert results[2]["type"] == "object"
    assert results[2]["variablesReference"] > 0


def test_d9_integrated_safe_unresolved_watch_expression():
    threads = ThreadStore()
    main = threads.ensure_main_thread()
    frame = threads.add_frame(
        main.id,
        name="main",
        source_path="examples/hello.pan",
        variables={"x": 1},
    )

    scopes = ScopeStore(thread_store=threads)
    evaluate = EvaluateEngine()
    evaluate.context.scope_store = scopes

    watch = WatchExpressionStore(evaluate_engine=evaluate)
    item = watch.add("missing_symbol", frame_id=frame.id)
    result = watch.evaluate_one(item.id)

    assert result["type"] == "unresolved"
    assert result["result"] == "<unresolved: missing_symbol>"
    assert result["variablesReference"] == 0


def test_d9_integrated_multi_thread_stack_traces_are_isolated():
    threads = ThreadStore()

    main = threads.ensure_main_thread()
    worker = threads.create_thread("Worker Thread")

    main_frame = threads.add_frame(
        main.id,
        name="main",
        source_path="main.pan",
        variables={"main_value": 1},
    )

    worker_frame = threads.add_frame(
        worker.id,
        name="worker",
        source_path="worker.pan",
        variables={"worker_value": 2},
    )

    main_trace = threads.stack_trace_body(main.id)
    worker_trace = threads.stack_trace_body(worker.id)

    assert main_trace["totalFrames"] == 1
    assert worker_trace["totalFrames"] == 1
    assert main_trace["stackFrames"][0]["id"] == main_frame.id
    assert worker_trace["stackFrames"][0]["id"] == worker_frame.id
    assert main_trace["stackFrames"][0]["name"] == "main"
    assert worker_trace["stackFrames"][0]["name"] == "worker"
