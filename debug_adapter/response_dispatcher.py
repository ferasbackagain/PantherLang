from __future__ import annotations
from typing import Any, Dict, Optional

class ResponseDispatcher:
    def success(self, command: str, request_seq: int=0, body: Optional[Dict[str, Any]]=None) -> Dict[str, Any]:
        return {"seq":0,"type":"response","request_seq":request_seq,"command":command,"success":True,"body":body or {}}
    def error(self, command: str, request_seq: int=0, message: str="error", body: Optional[Dict[str, Any]]=None) -> Dict[str, Any]:
        out={"seq":0,"type":"response","request_seq":request_seq,"command":command,"success":False,"message":message,"body":body or {}}
        return out
    def normalize(self, message: Any, request_seq: int=0, command: str|None=None) -> Dict[str, Any]:
        if message is None:
            return self.success(command or "", request_seq=request_seq)
        if isinstance(message, dict):
            if message.get("type")=="event":
                out=dict(message); out.setdefault("request_seq", request_seq)
                if command: out.setdefault("sourceCommand", command)
                return out
            if message.get("type")=="response":
                out=dict(message); out.setdefault("request_seq", request_seq); out.setdefault("command", command); out.setdefault("success", True); out.setdefault("body", {})
                return out
            body=message.get("body", message) if isinstance(message,dict) else message
            return self.success(command or "", request_seq=request_seq, body=body)
        return self.error(command or "", request_seq=request_seq, message=str(message))
