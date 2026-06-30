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
