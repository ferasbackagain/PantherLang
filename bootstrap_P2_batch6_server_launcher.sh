#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-2"
echo " Canonical Debug Adapter Rebuild"
echo " Batch 6 - Server + Launcher"
echo "============================================================"

ROOT="$(pwd)"
P2="$ROOT/.panther/p2_debug_adapter_rebuild"
REBUILT="$ROOT/debug_adapter_rebuilt"
REPORTS="$ROOT/reports/P2"
TESTS="$ROOT/tests/P2_canonical_debug_adapter"

mkdir -p "$REBUILT" "$REPORTS" "$TESTS"

[ -f "$P2/status_batch5.json" ] || { echo "[P2-B6][ERROR] Run Batch 5 first."; exit 1; }

cat > "$REBUILT/launcher.py" <<'PY'
from dataclasses import dataclass

@dataclass
class LaunchInfo:
    pid:int
    command:list

class Launcher:
    def launch(self, program, args=None, cwd=None, dry_run=True):
        cmd=["Panther","run",program]
        if args:
            cmd.extend(args)
        return LaunchInfo(pid=1000 if dry_run else 9999, command=cmd)
PY

cat > "$REBUILT/server.py" <<'PY'
from .launcher import Launcher
from .session import DebugSession
from .event_bus import EventBus
from .event_dispatcher import EventDispatcher
from .execution_dispatcher import ExecutionDispatcher
from .request_dispatcher import RequestDispatcher

class DebugServer:
    def __init__(self):
        self.bus=EventBus()
        self.events=EventDispatcher(self.bus)
        self.session=DebugSession()
        self.launcher=Launcher()
        self.execution=ExecutionDispatcher(self.events)
        self.dispatcher=RequestDispatcher(
            session=self.session,
            events=self.events,
            execution=self.execution
        )

    def dispatch(self, request):
        return self.dispatcher.dispatch(request)
PY

cat > "$TESTS/test_p2_batch6_server.py" <<'PY'
from debug_adapter_rebuilt.server import DebugServer

def test_server_flow():
    s=DebugServer()
    assert s.dispatch({"seq":1,"command":"initialize","arguments":{"adapterID":"panther"}})["success"]
    assert s.dispatch({"seq":2,"command":"configurationDone"})["success"]
    launch=s.dispatch({"seq":3,"command":"launch","arguments":{"program":"hello.pan"}})
    assert launch["type"]=="event"
    assert launch["event"]=="process"
    assert launch["body"]["name"]=="hello.pan"
    assert s.dispatch({"seq":4,"command":"continue"})["event"]=="continued"
    assert s.dispatch({"seq":5,"command":"terminate"})["event"]=="terminated"
PY

python3 -m py_compile "$REBUILT/launcher.py" "$REBUILT/server.py" "$TESTS/test_p2_batch6_server.py"
python3 -m pytest "$TESTS/test_p2_batch6_server.py" -q

cat > "$REPORTS/P2_BATCH6_SERVER.md" <<EOF
P2 Batch6 PASSED
EOF

cat > "$P2/status_batch6.json" <<EOF
{"ok":true,"phase":"P-2","batch":"6","status":"PASSED","next":"P-2 Batch 7 - Debug Data Model"}
EOF

echo "============================================================"
echo "✅ P-2 Batch 6 COMPLETE"
echo "Next: P-2 Batch 7 - Debug Data Model"
echo "============================================================"
