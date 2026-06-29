from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Optional


@dataclass(slots=True)
class ResponseEnvelope:
    """Canonical PantherLang Debug Adapter Protocol response envelope."""

    command: Optional[str]
    request_seq: Optional[int]
    success: bool = True
    body: Dict[str, Any] = field(default_factory=dict)
    message: Optional[str] = None

    def to_dap(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "type": "response",
            "request_seq": self.request_seq,
            "command": self.command,
            "success": bool(self.success),
        }
        if self.body:
            payload["body"] = dict(self.body)
        if self.message:
            payload["message"] = str(self.message)
        return payload


class ResponseMergeEngine:
    """
    Final response merge layer for H4.2.

    Preserves the public ResponseDispatcher contract while centralizing:
    - success response construction
    - error response construction
    - normalization of raw dictionaries into DAP responses
    - passthrough of real DAP events from execution routing
    """

    def success(
        self,
        command: Optional[str],
        request_seq: Optional[int] = None,
        body: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        return ResponseEnvelope(
            command=command,
            request_seq=request_seq,
            success=True,
            body=body or {},
        ).to_dap()

    def error(
        self,
        command: Optional[str],
        request_seq: Optional[int] = None,
        message: str = "request failed",
        body: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        return ResponseEnvelope(
            command=command,
            request_seq=request_seq,
            success=False,
            body=body or {},
            message=message,
        ).to_dap()

    def normalize(
        self,
        message: Any,
        request_seq: Optional[int] = None,
        command: Optional[str] = None,
    ) -> Dict[str, Any]:
        if not isinstance(message, dict):
            return self.success(command, request_seq=request_seq, body={"value": message})

        message_type = message.get("type")

        if message_type == "event":
            if request_seq is not None:
                message.setdefault("request_seq", request_seq)
            if command is not None:
                message.setdefault("sourceCommand", command)
            return message

        if message_type == "response":
            if message.get("request_seq") is None:
                message["request_seq"] = request_seq
            if message.get("command") is None:
                message["command"] = command
            message.setdefault("success", True)
            return message

        return self.success(command, request_seq=request_seq, body=message)

    def assert_response_contract(self, message: Dict[str, Any]) -> bool:
        if not isinstance(message, dict):
            raise AssertionError("response must be a dictionary")
        if message.get("type") != "response":
            raise AssertionError("response type must be 'response'")
        if "request_seq" not in message:
            raise AssertionError("response missing request_seq")
        if "command" not in message:
            raise AssertionError("response missing command")
        if "success" not in message:
            raise AssertionError("response missing success")
        return True
