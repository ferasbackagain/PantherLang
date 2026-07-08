from __future__ import annotations
from typing import Any, Dict, Optional, List
try:
    from .event_bus import EventBus
except Exception:
    class EventBus:
        def __init__(self): self.events=[]
        def emit(self, e): self.events.append(e)

class EventDispatcher:
    def __init__(self, bus: Optional[EventBus]=None):
        self.bus=bus if bus is not None else EventBus()
    def _emit(self, event: Dict[str, Any]) -> Dict[str, Any]:
        try: self.bus.emit(event)
        except Exception: pass
        return event
    def _add(self,event,request_seq=None):
        if request_seq is not None: event["request_seq"]=request_seq
        return self._emit(event)
    def initialized(self, request_seq: int|None=None):
        return self._add({"type":"event","event":"initialized","body":{}}, request_seq)
    def process(self, name: str, pid: int|None=None, system_process_id: int|None=None, command: Optional[List[str]]=None, state: str="running", execution: Optional[Dict[str, Any]]=None, request_seq: int|None=None, **extra):
        spid = system_process_id if system_process_id is not None else (0 if pid is None else pid)
        body={"name":name,"systemProcessId":spid,"isLocalProcess":True,"startMethod":"launch"}
        if command is not None: body["command"]=command
        if state is not None: body["state"]=state
        if execution is not None: body["execution"]=execution
        body.update(extra)
        return self._add({"type":"event","event":"process","body":body}, request_seq)
    def continued(self, thread_id: int=1, all_threads_continued: bool=True, request_seq: int|None=None):
        return self._add({"type":"event","event":"continued","body":{"threadId":thread_id,"allThreadsContinued":all_threads_continued,"status":"running"}}, request_seq)
    def stopped(self, reason: str="pause", thread_id: int=1, status: str|None=None, request_seq: int|None=None, **extra):
        body={"reason":reason,"threadId":thread_id,"allThreadsStopped":True,"status":"paused" if reason=="pause" else ("stopped" if reason=="stop" else reason)}
        if status is not None: body["status"]=status
        body.update(extra)
        return self._add({"type":"event","event":"stopped","body":body}, request_seq)
    def terminated(self, restart: bool=False, request_seq: int|None=None):
        return self._add({"type":"event","event":"terminated","body":{"restart":restart}}, request_seq)
    def exited(self, exit_code: int=0, request_seq: int|None=None):
        return self._add({"type":"event","event":"exited","body":{"exitCode":exit_code}}, request_seq)
    def output(self, text: str, category: str="console", request_seq: int|None=None):
        return self._add({"type":"event","event":"output","body":{"category":category,"output":text}}, request_seq)
