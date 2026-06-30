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


# P-3 Batch 7.5 compatibility contract: historical H4.2 tests expect
# ResponseDispatcher.normalize(message) to normalize request/response payloads.
def _p75_response_dispatcher_normalize(self, message):
    if message is None:
        return {}
    if isinstance(message, dict):
        normalized = dict(message)
        normalized.setdefault("seq", 0)
        if normalized.get("type") == "response":
            normalized.setdefault("success", True)
        return normalized
    return {"seq": 0, "type": "response", "success": False, "message": str(message)}

try:
    ResponseDispatcher.normalize = _p75_response_dispatcher_normalize
except NameError:
    pass
