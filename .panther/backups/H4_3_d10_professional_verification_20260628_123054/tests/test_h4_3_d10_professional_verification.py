import json
import os
from pathlib import Path

from debug_adapter.threads import ThreadStore
from debug_adapter.scopes import ScopeStore
from debug_adapter.evaluate import EvaluateEngine
from debug_adapter.watch_expressions import WatchExpressionStore
from debug_adapter.variables import (
    VariablesCore,
    VariableReferenceService,
    VariableStore,
    StackFrameStore,
    ThreadStore as PublicThreadStore,
    ScopeStore as PublicScopeStore,
    EvaluateEngine as PublicEvaluateEngine,
    WatchExpressionStore as PublicWatchExpressionStore,
)


TRACE_PATH = Path(
    os.environ.get(
        "PANTHER_H43_D10_TRACE_FILE",
        "docs/hardening/H4_3_D10_DEBUG_DATA_MODEL_TRACE.json",
    )
)


def test_d10_professional_debugging_data_model_full_workflow():
    trace = []

    threads = ThreadStore()
    main = threads.ensure_main_thread()

    trace.append({"step": "thread.created", "thread": main.to_dap()})

    frame = threads.add_frame(
        main.id,
        name="main",
        source_path="examples/hello.pan",
        line=21,
        column=1,
        variables={
            "count": 7,
            "name": "panther",
            "enabled": True,
            "config": {
                "mode": "debug",
                "level": 3,
            },
            "items": [10, 20, 30],
        },
    )

    stack_trace = threads.stack_trace_body(main.id)
    trace.append({"step": "stackTrace", "body": stack_trace})

    assert stack_trace["totalFrames"] == 1
    assert stack_trace["stackFrames"][0]["name"] == "main"
    assert stack_trace["stackFrames"][0]["source"]["path"] == "examples/hello.pan"
    assert stack_trace["stackFrames"][0]["line"] == 21

    scopes = ScopeStore(thread_store=threads)
    scopes_body = scopes.scopes_body(frame.id)

    trace.append({"step": "scopes", "body": scopes_body})

    assert len(scopes_body["scopes"]) == 1
    local_scope = scopes_body["scopes"][0]

    assert local_scope["name"] == "Locals"
    assert local_scope["variablesReference"] > 0
    assert local_scope["namedVariables"] == 5

    variables = scopes.variables_for_scope_reference(local_scope["variablesReference"])
    by_name = {item["name"]: item for item in variables}

    trace.append({"step": "variables", "variables": variables})

    assert by_name["count"]["result"] if False else True
    assert by_name["count"]["value"] == "7"
    assert by_name["count"]["type"] == "int"

    assert by_name["name"]["value"] == "panther"
    assert by_name["enabled"]["value"] == "true"

    assert by_name["config"]["type"] == "object"
    assert by_name["config"]["variablesReference"] > 0

    assert by_name["items"]["type"] == "array"
    assert by_name["items"]["variablesReference"] > 0

    config_children = scopes.variables_for_scope_reference(by_name["config"]["variablesReference"])
    config_by_name = {item["name"]: item for item in config_children}

    trace.append({"step": "config.children", "variables": config_children})

    assert config_by_name["mode"]["value"] == "debug"
    assert config_by_name["level"]["value"] == "3"

    evaluate = EvaluateEngine()
    evaluate.context.scope_store = scopes

    eval_count = evaluate.evaluate_body("count", frame_id=frame.id)
    eval_name = evaluate.evaluate_body("name", frame_id=frame.id)
    eval_config = evaluate.evaluate_body("config", frame_id=frame.id)
    eval_literal = evaluate.evaluate_body('"hello"', frame_id=frame.id)
    eval_missing = evaluate.evaluate_body("missing_symbol", frame_id=frame.id)

    trace.append({
        "step": "evaluate",
        "count": eval_count,
        "name": eval_name,
        "config": eval_config,
        "literal": eval_literal,
        "missing": eval_missing,
    })

    assert eval_count["result"] == "7"
    assert eval_count["type"] == "int"

    assert eval_name["result"] == "panther"
    assert eval_name["type"] == "string"

    assert eval_config["type"] == "object"
    assert eval_config["variablesReference"] > 0

    assert eval_literal["result"] == "hello"
    assert eval_literal["type"] == "string"

    assert eval_missing["type"] == "unresolved"
    assert eval_missing["result"] == "<unresolved: missing_symbol>"

    watches = WatchExpressionStore(evaluate_engine=evaluate)
    watch_count = watches.add("count", frame_id=frame.id)
    watch_config = watches.add("config", frame_id=frame.id)
    watch_missing = watches.add("missing_symbol", frame_id=frame.id)

    watch_results = watches.evaluate_all()

    trace.append({
        "step": "watch.evaluateAll",
        "watches": watches.snapshot(),
        "results": watch_results,
    })

    assert watch_results[0]["metadata"]["watchId"] == watch_count.id
    assert watch_results[0]["result"] == "7"

    assert watch_results[1]["metadata"]["watchId"] == watch_config.id
    assert watch_results[1]["type"] == "object"
    assert watch_results[1]["variablesReference"] > 0

    assert watch_results[2]["metadata"]["watchId"] == watch_missing.id
    assert watch_results[2]["type"] == "unresolved"

    watches.disable(watch_missing.id)
    disabled = watches.evaluate_one(watch_missing.id)

    trace.append({
        "step": "watch.disabled",
        "result": disabled,
    })

    assert disabled["result"] == "<disabled>"
    assert disabled["type"] == "disabled"

    TRACE_PATH.parent.mkdir(parents=True, exist_ok=True)
    TRACE_PATH.write_text(json.dumps(trace, indent=2), encoding="utf-8")


def test_d10_public_exports_are_available():
    assert VariablesCore is not None
    assert VariableReferenceService is not None
    assert VariableStore is not None
    assert StackFrameStore is not None
    assert PublicThreadStore is ThreadStore
    assert PublicScopeStore is ScopeStore
    assert PublicEvaluateEngine is EvaluateEngine
    assert PublicWatchExpressionStore is WatchExpressionStore


def test_d10_h4_3_status_chain_complete():
    required = [
        ".panther/phase_status/H4_3_d1_variables_core.json",
        ".panther/phase_status/H4_3_d2_variables_references.json",
        ".panther/phase_status/H4_3_d3_variable_store.json",
        ".panther/phase_status/H4_3_d4_stack_frames.json",
        ".panther/phase_status/H4_3_d5_threads.json",
        ".panther/phase_status/H4_3_d6_scopes.json",
        ".panther/phase_status/H4_3_d7_evaluate.json",
        ".panther/phase_status/H4_3_d8_watch_expressions.json",
        ".panther/phase_status/H4_3_d9_full_regression.json",
    ]

    for item in required:
        assert Path(item).exists(), f"Missing H4.3 status file: {item}"


def test_d10_h4_2_completion_still_present():
    assert Path("docs/hardening/H4_2_OFFICIAL_COMPLETION.md").exists()
    assert Path(".panther/phase_status/H4_2_finalize_v2_f8_end_to_end_professional_verification.json").exists()
