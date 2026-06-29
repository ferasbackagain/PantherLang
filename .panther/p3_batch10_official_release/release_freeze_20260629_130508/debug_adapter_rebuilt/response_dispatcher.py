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
