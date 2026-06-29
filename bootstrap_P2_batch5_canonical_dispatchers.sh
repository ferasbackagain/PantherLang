#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-2"
echo " Canonical Debug Adapter Rebuild"
echo " Batch 5 - Request/Response/Execution Dispatchers"
echo "============================================================"

ROOT="$(pwd)"
P2="$ROOT/.panther/p2_debug_adapter_rebuild"
REBUILT="$ROOT/debug_adapter_rebuilt"
REPORTS="$ROOT/reports/P2"
TESTS="$ROOT/tests/P2_canonical_debug_adapter"

mkdir -p "$REBUILT" "$REPORTS" "$TESTS"

[ -f "$P2/status_batch4.json" ] || { echo "[P2-B5][ERROR] Run Batch 4 first."; exit 1; }

cat > "$REBUILT/response_dispatcher.py" <<'PY'
from __future__ import annotations
from typing import Any, Dict, Optional


class ResponseDispatcher:
    def success(self, command: str, request_seq: int = 0, body: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        return {
            "seq": 0,
            "type": "response",
            "request_seq": request_seq,
            "command": command,
            "success": True,
            "body": body or {},
        }

    def error(self, command: str, request_seq: int = 0, message: str = "error") -> Dict[str, Any]:
        return {
            "seq": 0,
            "type": "response",
            "request_seq": request_seq,
            "command": command,
            "success": False,
            "message": message,
        }
PY

cat > "$REBUILT/execution_dispatcher.py" <<'PY'
from __future__ import annotations
from typing import Any, Dict, Optional

from .event_dispatcher import EventDispatcher


class ExecutionDispatcher:
    def __init__(self, events: Optional[EventDispatcher] = None):
        self.events = events if events is not None else EventDispatcher()
        self.status = "created"
        self.program = None
        self.current_line = 1

    def prepare(self, program: str, current_line: int = 1) -> Dict[str, Any]:
        self.status = "ready"
        self.program = program
        self.current_line = current_line
        return self.to_body()

    def launch(self, program: str, command=None, request_seq: int = 0) -> Dict[str, Any]:
        self.prepare(program)
        self.status = "running"
        return self.events.process(
            name=program,
            command=command,
            state=self.status,
            execution=self.to_body(),
            request_seq=request_seq,
        )

    def continue_(self, request_seq: int = 0) -> Dict[str, Any]:
        self.status = "running"
        return self.events.continued(request_seq=request_seq)

    def pause(self, request_seq: int = 0) -> Dict[str, Any]:
        self.status = "paused"
        return self.events.stopped(reason="pause", request_seq=request_seq)

    def stop(self, request_seq: int = 0) -> Dict[str, Any]:
        self.status = "stopped"
        return self.events.stopped(reason="stop", request_seq=request_seq)

    def terminate(self, request_seq: int = 0) -> Dict[str, Any]:
        self.status = "terminated"
        return self.events.terminated(request_seq=request_seq)

    def to_body(self) -> Dict[str, Any]:
        return {
            "status": self.status,
            "program": self.program,
            "currentLine": self.current_line,
        }
PY

cat > "$REBUILT/request_dispatcher.py" <<'PY'
from __future__ import annotations
from typing import Any, Dict, Optional

from .event_bus import EventBus
from .event_dispatcher import EventDispatcher
from .execution_dispatcher import ExecutionDispatcher
from .response_dispatcher import ResponseDispatcher
from .session import DebugSession


class RequestDispatcher:
    def __init__(
        self,
        session: Optional[DebugSession] = None,
        events: Optional[EventDispatcher] = None,
        responses: Optional[ResponseDispatcher] = None,
        execution: Optional[ExecutionDispatcher] = None,
    ):
        self.session = session if session is not None else DebugSession()
        self.events = events if events is not None else EventDispatcher(EventBus())
        self.responses = responses if responses is not None else ResponseDispatcher()
        self.execution = execution if execution is not None else ExecutionDispatcher(self.events)
        self.breakpoints = {}

    def dispatch(self, request: Dict[str, Any]) -> Dict[str, Any]:
        command = request.get("command")
        seq = request.get("seq", 0)
        arguments = request.get("arguments", {}) or {}

        if command == "initialize":
            self.session.apply_initialize_arguments(arguments)
            return self.responses.success(command, seq, self.session.capabilities())

        if command == "configurationDone":
            self.session.configuration_done()
            return self.responses.success(command, seq, {})

        if command == "setBreakpoints":
            source = arguments.get("source", {}).get("path", "unknown")
            bps = arguments.get("breakpoints", [])
            verified = [{"verified": True, "line": int(bp.get("line", 1))} for bp in bps]
            self.breakpoints[source] = verified
            return self.responses.success(command, seq, {"breakpoints": verified})

        if command == "launch":
            program = arguments.get("program", "main.pan")
            args = arguments.get("args", [])
            self.session.launch(program, args=args, cwd=arguments.get("cwd"))
            return self.execution.launch(program, command=["Panther", "run", program], request_seq=seq)

        if command == "continue":
            return self.execution.continue_(request_seq=seq)

        if command == "pause":
            return self.execution.pause(request_seq=seq)

        if command == "stop":
            return self.execution.stop(request_seq=seq)

        if command == "terminate":
            self.session.terminate()
            return self.execution.terminate(request_seq=seq)

        if command == "disconnect":
            self.session.disconnect()
            return self.responses.success(command, seq, {})

        return self.responses.error(command or "unknown", seq, f"unsupported command: {command}")
PY

cat > "$TESTS/test_p2_batch5_dispatchers.py" <<'PY'
from debug_adapter_rebuilt.request_dispatcher import RequestDispatcher
from debug_adapter_rebuilt.response_dispatcher import ResponseDispatcher
from debug_adapter_rebuilt.execution_dispatcher import ExecutionDispatcher
from debug_adapter_rebuilt.event_bus import EventBus
from debug_adapter_rebuilt.event_dispatcher import EventDispatcher


def test_response_dispatcher_contract():
    r = ResponseDispatcher()
    ok = r.success("initialize", 7, {"x": True})
    assert ok["type"] == "response"
    assert ok["success"] is True
    assert ok["request_seq"] == 7
    assert ok["body"]["x"] is True
    err = r.error("bad", 8, "no")
    assert err["success"] is False
    assert err["message"] == "no"


def test_execution_dispatcher_events():
    bus = EventBus()
    events = EventDispatcher(bus)
    ex = ExecutionDispatcher(events)
    launch = ex.launch("main.pan", request_seq=3)
    assert launch["type"] == "event"
    assert launch["event"] == "process"
    assert launch["request_seq"] == 3
    assert ex.pause(request_seq=4)["event"] == "stopped"
    assert ex.continue_(request_seq=5)["event"] == "continued"
    assert ex.terminate(request_seq=6)["event"] == "terminated"
    assert len(bus) == 4


def test_request_dispatcher_full_core_flow():
    d = RequestDispatcher()
    init = d.dispatch({"seq": 1, "type": "request", "command": "initialize", "arguments": {"adapterID": "panther"}})
    assert init["success"] is True
    assert init["body"]["panther"]["realDAPFraming"] is True

    config = d.dispatch({"seq": 2, "type": "request", "command": "configurationDone"})
    assert config["success"] is True

    bps = d.dispatch({
        "seq": 3,
        "type": "request",
        "command": "setBreakpoints",
        "arguments": {"source": {"path": "main.pan"}, "breakpoints": [{"line": 2}]},
    })
    assert bps["success"] is True
    assert bps["body"]["breakpoints"][0]["verified"] is True

    launch = d.dispatch({"seq": 4, "type": "request", "command": "launch", "arguments": {"program": "main.pan"}})
    assert launch["type"] == "event"
    assert launch["event"] == "process"
    assert launch["request_seq"] == 4

    cont = d.dispatch({"seq": 5, "type": "request", "command": "continue"})
    assert cont["event"] == "continued"

    pause = d.dispatch({"seq": 6, "type": "request", "command": "pause"})
    assert pause["event"] == "stopped"

    term = d.dispatch({"seq": 7, "type": "request", "command": "terminate"})
    assert term["event"] == "terminated"

    disc = d.dispatch({"seq": 8, "type": "request", "command": "disconnect"})
    assert disc["success"] is True
PY

python3 -m py_compile "$REBUILT/response_dispatcher.py" "$REBUILT/execution_dispatcher.py" "$REBUILT/request_dispatcher.py" "$TESTS/test_p2_batch5_dispatchers.py"
python3 -m pytest "$TESTS/test_p2_batch5_dispatchers.py" -q

cat > "$REPORTS/P2_BATCH5_CANONICAL_DISPATCHERS.md" <<'EOF'
# P-2 Batch 5 - Canonical Dispatchers

Status: PASSED

Implemented:
- ResponseDispatcher
- ExecutionDispatcher
- RequestDispatcher
- initialize/configurationDone/setBreakpoints/launch/continue/pause/stop/terminate/disconnect routing

Runtime Modification:
None. Existing debug_adapter/ was not modified.

Next:
P-2 Batch 6 - Server + Launcher.
EOF

cat > "$P2/status_batch5.json" <<'EOF'
{
  "ok": true,
  "phase": "P-2",
  "batch": "5",
  "status": "PASSED",
  "runtime_modified": false,
  "next": "P-2 Batch 6 - Server + Launcher"
}
EOF

echo "============================================================"
echo "✅ P-2 Batch 5 COMPLETE"
echo "Next: P-2 Batch 6 - Server + Launcher"
echo "============================================================"
