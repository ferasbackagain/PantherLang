#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3"
echo " Atomic Replacement Planning"
echo " Batch 3 - Dry-run Import Switch"
echo "============================================================"

ROOT="$(pwd)"
P3="$ROOT/.panther/p3_atomic_replacement"
REPORTS="$ROOT/reports/P3"
TESTS="$ROOT/tests/P3_atomic_replacement"

mkdir -p "$P3" "$REPORTS" "$TESTS"

[ -f "$P3/status_batch2.json" ] || { echo "[P3-B3][ERROR] Run Batch 2 first."; exit 1; }
[ -d "$ROOT/debug_adapter_bridge" ] || { echo "[P3-B3][ERROR] debug_adapter_bridge missing."; exit 1; }
[ -d "$ROOT/debug_adapter_rebuilt" ] || { echo "[P3-B3][ERROR] debug_adapter_rebuilt missing."; exit 1; }

echo "[1/7] Creating dry-run import switch tests..."

cat > "$TESTS/test_p3_batch3_dry_run_import_switch.py" <<'PY'
from io import StringIO, BytesIO

from debug_adapter_bridge.protocol import encode_message, read_message
from debug_adapter_bridge.session import DebugSession
from debug_adapter_bridge.event_bus import EventBus
from debug_adapter_bridge.event_dispatcher import EventDispatcher
from debug_adapter_bridge.request_dispatcher import RequestDispatcher
from debug_adapter_bridge.server import DebugServer
from debug_adapter_bridge.variable_store import VariableStore
from debug_adapter_bridge.evaluate import EvaluateEngine


def test_bridge_protocol_roundtrip_string_and_bytes():
    msg = {"seq": 1, "type": "request", "command": "initialize", "arguments": {"adapterID": "panther"}}
    framed = encode_message(msg)
    assert read_message(StringIO(framed)) == msg
    assert read_message(BytesIO(bytes(framed))) == msg


def test_bridge_session_contract():
    s = DebugSession()
    s.apply_initialize_arguments({"adapterID": "panther"})
    assert s.initialized is True
    assert s.capabilities()["panther"]["realDAPFraming"] is True
    s.configuration_done()
    assert s.state == "configured"


def test_bridge_event_dispatcher_contract():
    bus = EventBus()
    dispatcher = EventDispatcher(bus)
    event = dispatcher.process(
        name="main.pan",
        pid=123,
        command=["Panther", "run", "main.pan"],
        execution={"status": "ready"},
        request_seq=7,
    )
    assert event["type"] == "event"
    assert event["event"] == "process"
    assert event["request_seq"] == 7
    assert len(bus) == 1
    assert bus.drain()[0] == event


def test_bridge_request_dispatcher_core_flow():
    d = RequestDispatcher()
    assert d.dispatch({"seq": 1, "command": "initialize", "arguments": {"adapterID": "panther"}})["success"] is True
    assert d.dispatch({"seq": 2, "command": "configurationDone"})["success"] is True
    launch = d.dispatch({"seq": 3, "command": "launch", "arguments": {"program": "hello.pan"}})
    assert launch["type"] == "event"
    assert launch["event"] == "process"
    assert launch["request_seq"] == 3
    assert d.dispatch({"seq": 4, "command": "continue"})["event"] == "continued"
    assert d.dispatch({"seq": 5, "command": "pause"})["event"] == "stopped"
    assert d.dispatch({"seq": 6, "command": "terminate"})["event"] == "terminated"


def test_bridge_server_and_data_model():
    server = DebugServer()
    assert server.dispatch({"seq": 1, "command": "initialize", "arguments": {"adapterID": "panther"}})["success"] is True
    assert server.dispatch({"seq": 2, "command": "launch", "arguments": {"program": "x.pan"}})["event"] == "process"

    store = VariableStore()
    store.set("x", 5)
    assert store.get("x").value == "5"

    evaluator = EvaluateEngine({"x": 5})
    assert evaluator.evaluate("x + 1").result == "6"
PY

echo "[2/7] Static compilation..."
python3 -m py_compile $(find debug_adapter_bridge -name "*.py") "$TESTS/test_p3_batch3_dry_run_import_switch.py"

echo "[3/7] Running dry-run import switch tests..."
python3 -m pytest "$TESTS/test_p3_batch3_dry_run_import_switch.py" -q

echo "[4/7] Running existing P2 canonical suite through rebuilt package..."
python3 -m pytest tests/P2_canonical_debug_adapter -q

echo "[5/7] Writing dry-run switch report..."
cat > "$REPORTS/P3_BATCH3_DRY_RUN_IMPORT_SWITCH.md" <<'EOF'
# P-3 Batch 3 - Dry-run Import Switch

## Status

PASSED

## Purpose

Validate that the compatibility bridge can expose the rebuilt debug adapter API without replacing the production `debug_adapter/` directory.

## Verified

- Protocol imports through `debug_adapter_bridge`
- Session imports through `debug_adapter_bridge`
- EventBus and EventDispatcher imports through `debug_adapter_bridge`
- RequestDispatcher imports through `debug_adapter_bridge`
- DebugServer imports through `debug_adapter_bridge`
- VariableStore and EvaluateEngine imports through `debug_adapter_bridge`
- Existing P2 canonical suite still passes

## Runtime Modification

None. Existing `debug_adapter/` was not modified.

## Next

P-3 Batch 4 - Atomic Switch Plan + Rollback Package.
EOF

echo "[6/7] Writing status..."
cat > "$P3/status_batch3.json" <<'EOF'
{
  "ok": true,
  "phase": "P-3",
  "batch": "3",
  "status": "PASSED",
  "runtime_modified": false,
  "next": "P-3 Batch 4 - Atomic Switch Plan + Rollback Package"
}
EOF

echo "[7/7] Done."

echo "============================================================"
echo "✅ P-3 Batch 3 COMPLETE"
echo "Next: P-3 Batch 4 - Atomic Switch Plan + Rollback Package"
echo "============================================================"
