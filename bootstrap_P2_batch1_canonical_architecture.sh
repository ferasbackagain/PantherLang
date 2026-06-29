#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-2"
echo " Canonical Debug Adapter Rebuild"
echo " Batch 1 - Canonical Architecture Contract"
echo "============================================================"

ROOT="$(pwd)"
P2="$ROOT/.panther/p2_debug_adapter_rebuild"
REPORTS="$ROOT/reports/P2"
SPEC="$P2/spec"
TESTS="$ROOT/tests/P2_canonical_debug_adapter"

mkdir -p "$P2" "$REPORTS" "$SPEC" "$TESTS"

fail(){ echo "[P2-B1][ERROR] $1" >&2; exit 1; }

[ -d "$ROOT" ] || fail "Invalid root."
[ -d "$ROOT.tests" ] || true

echo "[1/7] Creating canonical architecture spec..."

cat > "$SPEC/CANONICAL_DEBUG_ADAPTER_ARCHITECTURE.md" <<'EOF'
# PantherLang Canonical Debug Adapter Architecture

## Purpose

This document defines the clean source-of-truth contract for the rebuilt PantherLang Debug Adapter.

The rebuilt adapter must be independent of historical monkey patches, backup drift, and phase-specific compatibility hacks.

## Core Rule

Never patch a drifting debug adapter architecture. Rebuild from the canonical contract, verify, then replace atomically.

## Required Modules

The rebuilt adapter will live first in:

`debug_adapter_rebuilt/`

and only replace `debug_adapter/` after full regression passes.

Required canonical modules:

- `protocol.py`
- `messages.py`
- `session.py`
- `event_bus.py`
- `event_dispatcher.py`
- `response_dispatcher.py`
- `request_dispatcher.py`
- `execution_dispatcher.py`
- `server.py`
- `launcher.py`
- `breakpoints.py`
- `variables_core.py`
- `variable_references.py`
- `variable_store.py`
- `stack_frames.py`
- `threads.py`
- `scopes.py`
- `evaluate.py`
- `watch_expressions.py`
- `adapter.py`
- `__init__.py`

## Protocol Contract

`encode_message(message)` must return a DAP frame compatible with both:
- bytes-based streams
- legacy StringIO tests

Therefore the canonical protocol must support:
- Content-Length framing
- CRLF separator
- JSON body
- round-trip decode via `read_message`

## Session Contract

`DebugSession` must support:
- initialize
- configurationDone
- launch
- terminate
- disconnect
- state transitions
- callable `capabilities()`
- `apply_initialize_arguments(arguments)`

Capabilities must include:

```json
{
  "supportsConfigurationDoneRequest": true,
  "supportsSetVariable": true,
  "supportsEvaluateForHovers": true,
  "supportsTerminateRequest": true,
  "panther": {
    "realDAPFraming": true,
    "adapter": "pantherlang",
    "protocol": "DAP"
  }
}
```

## Event Contract

EventDispatcher must return real DAP events for:
- launch/process
- continue
- pause
- stop
- terminate
- disconnect

Process event must accept:
- name
- pid
- command
- state
- execution
- request_seq

EventBus must support:
- emit
- publish
- push
- append
- drain
- len(bus)
- iteration

## Request Dispatcher Contract

RequestDispatcher must route:
- initialize -> response
- configurationDone -> response
- setBreakpoints -> response
- launch -> process event
- continue -> continued event
- pause -> stopped event
- stop -> stopped/terminated event
- terminate -> terminated event
- disconnect -> terminated/disconnect response/event compatible with tests

## Debug Data Model Contract

The rebuilt adapter must preserve H4.3 data model:
- variables
- variable references
- variable store
- stack frames
- threads
- scopes
- evaluate
- watch expressions

## Replacement Rule

The old `debug_adapter/` must not be replaced until:
- `debug_adapter_rebuilt/` compiles
- all P2 unit tests pass
- H4 regression passes
- engineering report is generated
- status JSON says replacement is allowed
EOF

echo "[2/7] Creating machine-readable contract..."

cat > "$SPEC/canonical_debug_adapter_contract.json" <<'EOF'
{
  "phase": "P-2",
  "batch": "1",
  "name": "Canonical Debug Adapter Architecture Contract",
  "runtime_modified": false,
  "target_directory": "debug_adapter_rebuilt",
  "atomic_replace_only_after_full_pass": true,
  "required_modules": [
    "protocol.py",
    "messages.py",
    "session.py",
    "event_bus.py",
    "event_dispatcher.py",
    "response_dispatcher.py",
    "request_dispatcher.py",
    "execution_dispatcher.py",
    "server.py",
    "launcher.py",
    "breakpoints.py",
    "variables_core.py",
    "variable_references.py",
    "variable_store.py",
    "stack_frames.py",
    "threads.py",
    "scopes.py",
    "evaluate.py",
    "watch_expressions.py",
    "adapter.py",
    "__init__.py"
  ],
  "dap_commands": [
    "initialize",
    "configurationDone",
    "setBreakpoints",
    "launch",
    "continue",
    "pause",
    "stop",
    "terminate",
    "disconnect",
    "threads",
    "stackTrace",
    "scopes",
    "variables",
    "evaluate"
  ],
  "required_capabilities": {
    "supportsConfigurationDoneRequest": true,
    "supportsSetVariable": true,
    "supportsEvaluateForHovers": true,
    "supportsTerminateRequest": true,
    "panther": {
      "realDAPFraming": true,
      "adapter": "pantherlang",
      "protocol": "DAP"
    }
  }
}
EOF

echo "[3/7] Creating canonical contract test..."

cat > "$TESTS/test_p2_batch1_contract.py" <<'PY'
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SPEC = ROOT / ".panther" / "p2_debug_adapter_rebuild" / "spec"

def test_p2_contract_exists_and_is_machine_readable():
    contract = SPEC / "canonical_debug_adapter_contract.json"
    assert contract.exists()
    data = json.loads(contract.read_text())
    assert data["phase"] == "P-2"
    assert data["batch"] == "1"
    assert data["runtime_modified"] is False
    assert data["target_directory"] == "debug_adapter_rebuilt"
    assert data["atomic_replace_only_after_full_pass"] is True

def test_p2_required_modules_cover_protocol_dispatcher_server_and_data_model():
    data = json.loads((SPEC / "canonical_debug_adapter_contract.json").read_text())
    modules = set(data["required_modules"])
    for name in [
        "protocol.py",
        "session.py",
        "event_bus.py",
        "event_dispatcher.py",
        "request_dispatcher.py",
        "execution_dispatcher.py",
        "server.py",
        "variables_core.py",
        "variable_references.py",
        "variable_store.py",
        "stack_frames.py",
        "threads.py",
        "scopes.py",
        "evaluate.py",
        "watch_expressions.py",
    ]:
        assert name in modules

def test_p2_contract_includes_required_dap_commands_and_capabilities():
    data = json.loads((SPEC / "canonical_debug_adapter_contract.json").read_text())
    commands = set(data["dap_commands"])
    for cmd in ["initialize", "configurationDone", "setBreakpoints", "launch", "continue", "pause", "terminate", "disconnect", "evaluate"]:
        assert cmd in commands
    caps = data["required_capabilities"]
    assert caps["supportsConfigurationDoneRequest"] is True
    assert caps["supportsSetVariable"] is True
    assert caps["panther"]["realDAPFraming"] is True
PY

echo "[4/7] Running static validation..."
python3 -m json.tool "$SPEC/canonical_debug_adapter_contract.json" >/dev/null
python3 -m py_compile "$TESTS/test_p2_batch1_contract.py"

echo "[5/7] Running Batch 1 tests..."
python3 -m pytest "$TESTS/test_p2_batch1_contract.py" -q

echo "[6/7] Writing engineering report..."

cat > "$REPORTS/P2_BATCH1_CANONICAL_ARCHITECTURE.md" <<'EOF'
# P-2 Batch 1 - Canonical Debug Adapter Architecture

## Status

PASSED

## Purpose

Establish the canonical contract for rebuilding PantherLang Debug Adapter from a clean architecture instead of continuing monkey patches.

## Outputs

- `.panther/p2_debug_adapter_rebuild/spec/CANONICAL_DEBUG_ADAPTER_ARCHITECTURE.md`
- `.panther/p2_debug_adapter_rebuild/spec/canonical_debug_adapter_contract.json`
- `tests/P2_canonical_debug_adapter/test_p2_batch1_contract.py`

## Runtime Modification

None.

## Next

P-2 Batch 2 - Build canonical `protocol.py` and protocol tests inside `debug_adapter_rebuilt/`.
EOF

cat > "$P2/status_batch1.json" <<'EOF'
{
  "ok": true,
  "phase": "P-2",
  "batch": "1",
  "status": "PASSED",
  "runtime_modified": false,
  "next": "P-2 Batch 2 - Canonical Protocol"
}
EOF

echo "[7/7] Done."

echo "============================================================"
echo "✅ P-2 Batch 1 COMPLETE"
echo "Next: P-2 Batch 2 - Canonical Protocol"
echo "============================================================"
