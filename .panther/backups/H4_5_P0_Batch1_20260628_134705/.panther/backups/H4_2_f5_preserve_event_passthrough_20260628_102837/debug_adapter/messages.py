from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass(slots=True)
class DAPMessage:
    """A typed DAP message container."""

    seq: int
    type: str
    raw: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class DAPRequest(DAPMessage):
    command: str = ""
    arguments: dict[str, Any] = field(default_factory=dict)

    @classmethod
    def from_raw(cls, raw: dict[str, Any]) -> "DAPRequest":
        return cls(
            seq=int(raw.get("seq", 0)),
            type=str(raw.get("type", "request")),
            raw=raw,
            command=str(raw.get("command", "")),
            arguments=dict(raw.get("arguments") or {}),
        )


def response(seq: int, request: DAPRequest, *, success: bool = True, body: dict[str, Any] | None = None, message: str | None = None) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "seq": seq,
        "type": "response",
        "request_seq": request.seq,
        "success": success,
        "command": request.command,
    }
    if message:
        payload["message"] = message
    if body is not None:
        payload["body"] = body
    return payload


def event(seq: int, name: str, body: dict[str, Any] | None = None) -> dict[str, Any]:
    payload: dict[str, Any] = {"seq": seq, "type": "event", "event": name}
    if body is not None:
        payload["body"] = body
    return payload
