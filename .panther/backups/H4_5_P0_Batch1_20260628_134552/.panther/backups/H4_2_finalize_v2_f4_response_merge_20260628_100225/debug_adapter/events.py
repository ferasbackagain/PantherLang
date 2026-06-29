from dataclasses import dataclass, field
from typing import Any, Dict, Optional


@dataclass
class DAPEvent:
    event: str
    body: Dict[str, Any] = field(default_factory=dict)
    request_seq: Optional[int] = None
    source_command: Optional[str] = None

    def to_dap(self):
        message = {"type": "event", "event": self.event}
        if self.body:
            message["body"] = self.body
        if self.request_seq is not None:
            message["request_seq"] = self.request_seq
        if self.source_command:
            message["sourceCommand"] = self.source_command
        return message


@dataclass
class DAPResponse:
    command: Optional[str]
    request_seq: Optional[int]
    success: bool = True
    body: Dict[str, Any] = field(default_factory=dict)
    message: Optional[str] = None

    def to_dap(self):
        response = {
            "type": "response",
            "request_seq": self.request_seq,
            "command": self.command,
            "success": self.success,
        }
        if self.body:
            response["body"] = self.body
        if self.message:
            response["message"] = self.message
        return response


def dap_event(event, body=None, request_seq=None, source_command=None):
    return DAPEvent(event=event, body=body or {}, request_seq=request_seq, source_command=source_command).to_dap()


def dap_response(command, request_seq=None, success=True, body=None, message=None):
    return DAPResponse(
        command=command,
        request_seq=request_seq,
        success=success,
        body=body or {},
        message=message,
    ).to_dap()
