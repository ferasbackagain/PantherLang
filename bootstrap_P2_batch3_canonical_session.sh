#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-2"
echo " Canonical Debug Adapter Rebuild"
echo " Batch 3 - Canonical Session"
echo "============================================================"

ROOT="$(pwd)"
P2="$ROOT/.panther/p2_debug_adapter_rebuild"
REBUILT="$ROOT/debug_adapter_rebuilt"
REPORTS="$ROOT/reports/P2"
TESTS="$ROOT/tests/P2_canonical_debug_adapter"

mkdir -p "$REBUILT" "$REPORTS" "$TESTS"

[ -f "$P2/status_batch2.json" ] || { echo "[P2-B3][ERROR] Run Batch 2 first."; exit 1; }

cat > "$REBUILT/session.py" <<'PY'
from dataclasses import dataclass, field

@dataclass
class DebugSession:
    state: str = "created"
    initialized: bool = False
    _capabilities: dict = field(default_factory=lambda:{
        "supportsConfigurationDoneRequest": True,
        "supportsSetVariable": True,
        "supportsEvaluateForHovers": True,
        "supportsTerminateRequest": True,
        "panther":{
            "realDAPFraming":True,
            "adapter":"pantherlang",
            "protocol":"DAP"
        }
    })
    initialize_args: dict = field(default_factory=dict)

    def apply_initialize_arguments(self, arguments):
        self.initialize_args=dict(arguments or {})
        self.initialized=True
        self.state="initialized"

    def capabilities(self):
        return dict(self._capabilities)

    def configuration_done(self):
        self.state="configured"

    def launch(self, program=None, args=None, cwd=None):
        self.state="running"
        return {"state":self.state,"program":program,"args":args or [],"cwd":cwd}

    def terminate(self):
        self.state="terminated"

    def disconnect(self):
        self.state="disconnected"
PY

cat > "$TESTS/test_p2_batch3_session.py" <<'PY'
from debug_adapter_rebuilt.session import DebugSession

def test_session_contract():
    s=DebugSession()
    s.apply_initialize_arguments({"adapterID":"panther"})
    assert s.initialized
    assert s.state=="initialized"
    assert s.capabilities()["panther"]["realDAPFraming"]
    s.configuration_done()
    assert s.state=="configured"
    info=s.launch("main.pan")
    assert info["program"]=="main.pan"
    assert s.state=="running"
    s.terminate()
    assert s.state=="terminated"
    s.disconnect()
    assert s.state=="disconnected"
PY

python3 -m py_compile "$REBUILT/session.py" "$TESTS/test_p2_batch3_session.py"
python3 -m pytest "$TESTS/test_p2_batch3_session.py" -q

cat > "$REPORTS/P2_BATCH3_CANONICAL_SESSION.md" <<EOF
P2 Batch3 PASSED
Canonical DebugSession implemented in debug_adapter_rebuilt.
EOF

cat > "$P2/status_batch3.json" <<EOF
{"ok":true,"phase":"P-2","batch":"3","status":"PASSED","runtime_modified":false,"next":"P-2 Batch 4 - Event Bus + Event Dispatcher"}
EOF

echo "============================================================"
echo "✅ P-2 Batch 3 COMPLETE"
echo "Next: P-2 Batch 4 - Event Bus + Event Dispatcher"
echo "============================================================"
