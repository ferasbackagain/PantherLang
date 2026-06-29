#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-2"
echo " Canonical Debug Adapter Rebuild"
echo " Batch 8 - Integration Regression"
echo "============================================================"

ROOT="$(pwd)"
P2="$ROOT/.panther/p2_debug_adapter_rebuild"
REBUILT="$ROOT/debug_adapter_rebuilt"
REPORTS="$ROOT/reports/P2"
TESTS="$ROOT/tests/P2_canonical_debug_adapter"

mkdir -p "$REPORTS" "$TESTS"

[ -f "$P2/status_batch7.json" ] || { echo "[P2-B8][ERROR] Run Batch 7 first."; exit 1; }

cat > "$TESTS/test_p2_batch8_integration_regression.py" <<'PY'
from io import StringIO, BytesIO

from debug_adapter_rebuilt.protocol import encode_message, read_message
from debug_adapter_rebuilt.server import DebugServer
from debug_adapter_rebuilt.request_dispatcher import RequestDispatcher
from debug_adapter_rebuilt.event_bus import EventBus
from debug_adapter_rebuilt.event_dispatcher import EventDispatcher
from debug_adapter_rebuilt.execution_dispatcher import ExecutionDispatcher
from debug_adapter_rebuilt.variable_store import VariableStore
from debug_adapter_rebuilt.stack_frames import StackFrameStore
from debug_adapter_rebuilt.threads import ThreadStore
from debug_adapter_rebuilt.scopes import ScopeStore
from debug_adapter_rebuilt.evaluate import EvaluateEngine


def test_protocol_dispatcher_end_to_end_flow_stringio_and_bytesio():
    dispatcher = RequestDispatcher()
    sequence = [
        {"seq": 1, "type": "request", "command": "initialize", "arguments": {"adapterID": "panther"}},
        {"seq": 2, "type": "request", "command": "configurationDone"},
        {"seq": 3, "type": "request", "command": "setBreakpoints", "arguments": {"source": {"path": "hello.pan"}, "breakpoints": [{"line": 1}]}},
        {"seq": 4, "type": "request", "command": "launch", "arguments": {"program": "hello.pan", "dryRun": True}},
        {"seq": 5, "type": "request", "command": "continue"},
        {"seq": 6, "type": "request", "command": "pause"},
        {"seq": 7, "type": "request", "command": "terminate"},
        {"seq": 8, "type": "request", "command": "disconnect"},
    ]

    responses = []
    for req in sequence:
        framed = encode_message(req)
        assert read_message(StringIO(framed)) == req
        assert read_message(BytesIO(bytes(framed))) == req
        responses.append(dispatcher.dispatch(req))

    assert responses[0]["success"] is True
    assert responses[0]["body"]["panther"]["realDAPFraming"] is True
    assert responses[1]["success"] is True
    assert responses[2]["body"]["breakpoints"][0]["verified"] is True
    assert responses[3]["type"] == "event" and responses[3]["event"] == "process"
    assert responses[4]["event"] == "continued"
    assert responses[5]["event"] == "stopped"
    assert responses[6]["event"] == "terminated"
    assert responses[7]["success"] is True


def test_server_integration_flow_and_event_bus():
    server = DebugServer()
    assert server.dispatch({"seq": 1, "command": "initialize", "arguments": {"adapterID": "panther"}})["success"] is True
    assert server.dispatch({"seq": 2, "command": "configurationDone"})["success"] is True
    launch = server.dispatch({"seq": 3, "command": "launch", "arguments": {"program": "main.pan"}})
    assert launch["event"] == "process"
    assert launch["body"]["name"] == "main.pan"
    assert len(server.bus) == 1
    assert server.bus.drain()[0] == launch


def test_execution_and_data_model_integration():
    bus = EventBus()
    events = EventDispatcher(bus)
    execution = ExecutionDispatcher(events)
    event = execution.launch("program.pan", request_seq=10)
    assert event["request_seq"] == 10
    assert event["body"]["execution"]["status"] == "running"

    variables = VariableStore()
    variables.set("x", 10)
    variables.set("obj", {"a": 1})

    frames = StackFrameStore()
    frame = frames.push("main", line=12, source_path="program.pan")

    threads = ThreadStore()
    scopes = ScopeStore()
    scope = scopes.add("Locals", variablesReference=variables.get("obj").variablesReference)

    evaluator = EvaluateEngine({"x": 10, "y": 5})
    assert evaluator.evaluate("x + y").result == "15"
    assert frame.line == 12
    assert threads.main().id == 1
    assert scope.name == "Locals"
PY

echo "[1/5] Static compile of rebuilt adapter..."
python3 -m py_compile $(find "$REBUILT" -name "*.py") "$TESTS/test_p2_batch8_integration_regression.py"

echo "[2/5] Running all P-2 canonical tests..."
python3 -m pytest "$TESTS" -q

echo "[3/5] Generating integration report..."
cat > "$REPORTS/P2_BATCH8_INTEGRATION_REGRESSION.md" <<'EOF'
# P-2 Batch 8 - Integration Regression

Status: PASSED

Scope:
- Protocol + RequestDispatcher end-to-end
- Server + EventBus integration
- Execution + Debug Data Model integration
- All P-2 canonical tests

Runtime Modification:
None. Existing debug_adapter/ was not modified.

Next:
P-2 Batch 9 - Professional Verification.
EOF

cat > "$P2/status_batch8.json" <<'EOF'
{
  "ok": true,
  "phase": "P-2",
  "batch": "8",
  "status": "PASSED",
  "runtime_modified": false,
  "next": "P-2 Batch 9 - Professional Verification"
}
EOF

echo "[4/5] Status written."
echo "[5/5] Done."

echo "============================================================"
echo "✅ P-2 Batch 8 COMPLETE"
echo "Next: P-2 Batch 9 - Professional Verification"
echo "============================================================"
