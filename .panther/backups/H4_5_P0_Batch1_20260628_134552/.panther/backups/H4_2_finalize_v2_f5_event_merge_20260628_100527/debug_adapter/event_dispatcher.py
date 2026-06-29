from .event_bus import EventBus
from .events import dap_event


class EventDispatcher:
    def __init__(self, bus=None):
        self.bus = bus if bus is not None else EventBus()

    def emit(self, event, body=None, request_seq=None, source_command=None):
        message = dap_event(event, body or {}, request_seq=request_seq, source_command=source_command)
        return self.bus.publish(message)

    def process(self, name, command, pid=None, state=None, execution=None, request_seq=None):
        body = {
            "name": name,
            "systemProcessId": pid,
            "isLocalProcess": True,
            "startMethod": "launch",
            "state": state,
            "execution": execution or {},
            "command": command,
        }
        return self.emit("process", body, request_seq=request_seq, source_command="launch")

    def continued(self, thread_id=1, status="running", reason="continued", request_seq=None):
        return self.emit(
            "continued",
            {
                "threadId": thread_id,
                "allThreadsContinued": True,
                "status": status,
                "reason": reason,
            },
            request_seq=request_seq,
            source_command="continue",
        )

    def stopped(self, reason, thread_id=1, status="paused", request_seq=None, source_command=None):
        return self.emit(
            "stopped",
            {
                "reason": reason,
                "threadId": thread_id,
                "allThreadsStopped": True,
                "status": status,
            },
            request_seq=request_seq,
            source_command=source_command or reason,
        )

    def terminated(self, request_seq=None):
        return self.emit("terminated", {}, request_seq=request_seq, source_command="terminate")

    def exited(self, exit_code=0, request_seq=None):
        return self.emit("exited", {"exitCode": exit_code}, request_seq=request_seq, source_command="disconnect")
