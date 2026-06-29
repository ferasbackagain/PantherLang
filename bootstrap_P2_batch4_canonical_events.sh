#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-2"
echo " Canonical Debug Adapter Rebuild"
echo " Batch 4 - Event Bus + Event Dispatcher"
echo "============================================================"

ROOT="$(pwd)"
P2="$ROOT/.panther/p2_debug_adapter_rebuild"
REBUILT="$ROOT/debug_adapter_rebuilt"
REPORTS="$ROOT/reports/P2"
TESTS="$ROOT/tests/P2_canonical_debug_adapter"

mkdir -p "$REBUILT" "$REPORTS" "$TESTS"

[ -f "$P2/status_batch3.json" ] || { echo "[P2-B4][ERROR] Run Batch 3 first."; exit 1; }

cat > "$REBUILT/event_bus.py" <<'PY'
from __future__ import annotations

from typing import Any, Dict, Iterator, List


class EventBus:
    """Canonical in-memory event queue for DAP events."""

    def __init__(self):
        self._events: List[Dict[str, Any]] = []

    def emit(self, event: Dict[str, Any]) -> Dict[str, Any]:
        if not isinstance(event, dict):
            raise TypeError("event must be dict")
        self._events.append(event)
        return event

    publish = emit
    push = emit
    append = emit

    def drain(self) -> List[Dict[str, Any]]:
        events = list(self._events)
        self._events.clear()
        return events

    def peek(self) -> List[Dict[str, Any]]:
        return list(self._events)

    def __len__(self) -> int:
        return len(self._events)

    def __iter__(self) -> Iterator[Dict[str, Any]]:
        return iter(self._events)
PY

cat > "$REBUILT/event_dispatcher.py" <<'PY'
from __future__ import annotations

from typing import Any, Dict, List, Optional

from .event_bus import EventBus


class EventDispatcher:
    """Canonical DAP event dispatcher."""

    def __init__(self, bus: Optional[EventBus] = None):
        self.bus = bus if bus is not None else EventBus()

    def _emit(self, event: Dict[str, Any]) -> Dict[str, Any]:
        self.bus.emit(event)
        return event

    def process(
        self,
        name: str,
        pid: Optional[int] = None,
        command: Optional[List[str]] = None,
        state: str = "running",
        execution: Optional[Dict[str, Any]] = None,
        request_seq: Optional[int] = None,
        **extra: Any,
    ) -> Dict[str, Any]:
        body: Dict[str, Any] = {
            "name": name,
            "systemProcessId": 0 if pid is None else pid,
            "isLocalProcess": True,
            "startMethod": "launch",
        }
        if command is not None:
            body["command"] = command
        if state is not None:
            body["state"] = state
        if execution is not None:
            body["execution"] = execution
        body.update(extra)

        event: Dict[str, Any] = {
            "type": "event",
            "event": "process",
            "body": body,
        }
        if request_seq is not None:
            event["request_seq"] = request_seq
        return self._emit(event)

    def continued(self, thread_id: int = 1, all_threads_continued: bool = True, request_seq: Optional[int] = None) -> Dict[str, Any]:
        event: Dict[str, Any] = {
            "type": "event",
            "event": "continued",
            "body": {
                "threadId": thread_id,
                "allThreadsContinued": all_threads_continued,
            },
        }
        if request_seq is not None:
            event["request_seq"] = request_seq
        return self._emit(event)

    def stopped(self, reason: str = "pause", thread_id: int = 1, request_seq: Optional[int] = None) -> Dict[str, Any]:
        event: Dict[str, Any] = {
            "type": "event",
            "event": "stopped",
            "body": {
                "reason": reason,
                "threadId": thread_id,
                "allThreadsStopped": True,
            },
        }
        if request_seq is not None:
            event["request_seq"] = request_seq
        return self._emit(event)

    def terminated(self, restart: bool = False, request_seq: Optional[int] = None) -> Dict[str, Any]:
        event: Dict[str, Any] = {
            "type": "event",
            "event": "terminated",
            "body": {
                "restart": restart,
            },
        }
        if request_seq is not None:
            event["request_seq"] = request_seq
        return self._emit(event)

    def output(self, text: str, category: str = "console", request_seq: Optional[int] = None) -> Dict[str, Any]:
        event: Dict[str, Any] = {
            "type": "event",
            "event": "output",
            "body": {
                "category": category,
                "output": text,
            },
        }
        if request_seq is not None:
            event["request_seq"] = request_seq
        return self._emit(event)
PY

cat > "$TESTS/test_p2_batch4_events.py" <<'PY'
from debug_adapter_rebuilt.event_bus import EventBus
from debug_adapter_rebuilt.event_dispatcher import EventDispatcher


def test_event_bus_emit_len_drain_contract():
    bus = EventBus()
    assert len(bus) == 0
    event = {"type": "event", "event": "output", "body": {"output": "ok"}}
    assert bus.emit(event) == event
    assert len(bus) == 1
    assert list(bus) == [event]
    assert bus.drain() == [event]
    assert len(bus) == 0


def test_process_event_accepts_server_signature_and_preserves_request_seq():
    bus = EventBus()
    dispatcher = EventDispatcher(bus)

    event = dispatcher.process(
        name="main.pan",
        pid=123,
        command=["Panther", "run", "main.pan"],
        state="running",
        execution={"status": "ready"},
        request_seq=7,
    )

    assert event["type"] == "event"
    assert event["event"] == "process"
    assert event["request_seq"] == 7
    assert event["body"]["systemProcessId"] == 123
    assert event["body"]["execution"]["status"] == "ready"
    assert len(bus) == 1
    assert bus.drain()[0] == event


def test_control_events():
    bus = EventBus()
    dispatcher = EventDispatcher(bus)

    continued = dispatcher.continued(request_seq=1)
    paused = dispatcher.stopped(reason="pause", request_seq=2)
    terminated = dispatcher.terminated(request_seq=3)

    assert continued["event"] == "continued"
    assert paused["event"] == "stopped"
    assert paused["body"]["reason"] == "pause"
    assert terminated["event"] == "terminated"
    assert [e["request_seq"] for e in bus.drain()] == [1, 2, 3]
PY

python3 -m py_compile "$REBUILT/event_bus.py" "$REBUILT/event_dispatcher.py" "$TESTS/test_p2_batch4_events.py"
python3 -m pytest "$TESTS/test_p2_batch4_events.py" -q

cat > "$REPORTS/P2_BATCH4_CANONICAL_EVENTS.md" <<'EOF'
# P-2 Batch 4 - Canonical Events

Status: PASSED

Implemented:
- EventBus
- EventDispatcher
- process event
- continued event
- stopped event
- terminated event
- output event

Runtime Modification:
None. Existing debug_adapter/ was not modified.

Next:
P-2 Batch 5 - Request/Response/Execution Dispatchers.
EOF

cat > "$P2/status_batch4.json" <<'EOF'
{
  "ok": true,
  "phase": "P-2",
  "batch": "4",
  "status": "PASSED",
  "runtime_modified": false,
  "next": "P-2 Batch 5 - Request/Response/Execution Dispatchers"
}
EOF

echo "============================================================"
echo "✅ P-2 Batch 4 COMPLETE"
echo "Next: P-2 Batch 5 - Request/Response/Execution Dispatchers"
echo "============================================================"
