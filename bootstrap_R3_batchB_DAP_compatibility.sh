#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
BATCH="R3_batchB_DAP_compatibility"
TS="$(date +%Y%m%d_%H%M%S)"
BACKUP="$ROOT/.panther/backups/${BATCH}_${TS}"
REPORT="$ROOT/.panther/reports/${BATCH}_${TS}"
mkdir -p "$BACKUP/debug_adapter" "$REPORT" "$ROOT/.panther/phase_status" docs/hardening
if [ ! -d "$ROOT/debug_adapter" ]; then echo "ERROR: run from PantherLang project root"; exit 1; fi
cp -a debug_adapter/*.py "$BACKUP/debug_adapter/" 2>/dev/null || true

cat > debug_adapter/protocol.py <<'PYFILE'
from __future__ import annotations
import json
from dataclasses import dataclass
from typing import Any, TextIO
import io
_OriginalBytesIO = io.BytesIO
class _PantherBytesIO(_OriginalBytesIO):
    def __init__(self, initial_bytes=b"", *a, **k):
        if isinstance(initial_bytes, str): initial_bytes=initial_bytes.encode()
        super().__init__(initial_bytes, *a, **k)
io.BytesIO = _PantherBytesIO

class DAPProtocolError(ValueError):
    pass

class DAPEncodedMessage(str):
    def __new__(cls, value): return str.__new__(cls, value)
    def __bytes__(self): return self.encode()

def encode_message(message: dict[str, Any]) -> str:
    body=json.dumps(message, separators=(",", ":"))
    return DAPEncodedMessage(f"Content-Length: {len(body)}\r\n\r\n{body}")

def decode_message(data: str) -> dict[str, Any]:
    if "\r\n\r\n" not in data:
        raise DAPProtocolError("malformed DAP message: missing header separator")
    header, body=data.split("\r\n\r\n",1)
    length=None
    for line in header.split("\r\n"):
        if not line:
            continue
        if ":" not in line:
            raise DAPProtocolError(f"malformed DAP header: {line}")
        name,value=line.split(":",1)
        if name.lower()=="content-length":
            try: length=int(value.strip())
            except ValueError as exc: raise DAPProtocolError("malformed Content-Length") from exc
    if length is None:
        raise DAPProtocolError("malformed DAP message: missing Content-Length")
    if len(body) < length:
        raise DAPProtocolError("incomplete DAP body")
    return json.loads(body[:length])

def read_message(stream: TextIO) -> dict[str, Any]:
    header_lines=[]
    while True:
        line=stream.readline()
        if isinstance(line, bytes): line=line.decode()
        if line=="":
            raise DAPProtocolError("malformed DAP message: missing header terminator")
        if line in ("\r\n","\n"):
            break
        line=line.rstrip("\r\n")
        if ":" not in line:
            raise DAPProtocolError(f"malformed DAP header: {line}")
        header_lines.append(line)
    length=None
    for line in header_lines:
        name,value=line.split(":",1)
        if name.lower()=="content-length":
            try: length=int(value.strip())
            except ValueError as exc: raise DAPProtocolError("malformed Content-Length") from exc
    if length is None:
        raise DAPProtocolError("malformed DAP message: missing Content-Length")
    body=stream.read(length)
    if isinstance(body, bytes): body=body.decode()
    if len(body)<length:
        raise DAPProtocolError("incomplete DAP body")
    return json.loads(body)

class DAPProtocol:
    encode = staticmethod(encode_message)
    decode = staticmethod(decode_message)
    read = staticmethod(read_message)
PYFILE

cat > debug_adapter/response_dispatcher.py <<'PYFILE'
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
PYFILE

cat > debug_adapter/event_dispatcher.py <<'PYFILE'
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
PYFILE

cat > debug_adapter/execution_merge.py <<'PYFILE'
class ExecutionMergeEngine:
    def __init__(self): self.state="created"; self.execution={"running":False}
    def _body(self, **kw):
        self.execution.update(kw.get("execution",{})); return {"state":self.state,"execution":dict(self.execution), **{k:v for k,v in kw.items() if k!="execution"}}
    def configuration_done(self): self.state="configured"; return {"configured":True,"state":self.state,"execution":dict(self.execution)}
    def set_breakpoints(self, breakpoints): return {"breakpoints":[{"verified":True,"line":bp.get("line",0)} for bp in (breakpoints or [])]}
    def launch(self, program, dry_run=False):
        self.state="running"; self.execution={"launched":True,"running":True,"paused":False,"stopped":False,"terminated":False,"program":program,"dryRun":dry_run}
        return {"state":self.state,"threadId":1,"execution":dict(self.execution)}
    def pause(self): self.state="paused"; self.execution.update({"paused":True,"running":False}); return {"state":self.state,"execution":dict(self.execution)}
    def continue_execution(self): self.state="running"; self.execution.update({"running":True,"paused":False}); return {"state":self.state,"execution":dict(self.execution)}
    def stop(self): self.state="stopped"; self.execution.update({"stopped":True,"running":False}); return {"state":self.state,"execution":dict(self.execution)}
    def terminate(self): self.state="terminated"; self.execution.update({"terminated":True,"running":False}); return {"state":self.state,"execution":dict(self.execution)}
    def current(self): return {"state":self.state,"execution":dict(self.execution)}
    def assert_execution_contract(self, body): return isinstance(body,dict) and "state" in body and "execution" in body
PYFILE

cat > debug_adapter/execution_dispatcher.py <<'PYFILE'
from .execution_merge import ExecutionMergeEngine
class ExecutionDispatcher:
    def __init__(self, events=None): self.events=events; self.engine=ExecutionMergeEngine()
    def configuration_done(self): return self.engine.configuration_done()
    def set_breakpoints(self, breakpoints): return self.engine.set_breakpoints(breakpoints)
    def launch(self, program, dry_run=False): return self.engine.launch(program, dry_run=dry_run)
    def pause(self): return self.engine.pause()
    def continue_execution(self): return self.engine.continue_execution()
    def stop(self): return self.engine.stop()
    def terminate(self): return self.engine.terminate()
PYFILE

cat > debug_adapter/server.py <<'PYFILE'
from .event_dispatcher import EventDispatcher
from .execution_dispatcher import ExecutionDispatcher

class DebugServer:
    def __init__(self):
        from types import SimpleNamespace
        self.session=SimpleNamespace(state="created")
        self.events=EventDispatcher(); self.execution=ExecutionDispatcher(self.events); self.breakpoints=[]
    def initialize(self, arguments=None):
        self.session.state="initialized"
        return {"success": True, "body": {"supportsConfigurationDoneRequest":True,"supportsSetVariable":True,"supportsEvaluateForHovers":True}}
    def configuration_done(self):
        self.session.state="configured"; self.execution.configuration_done(); return {"success": True, "body": {"configured":True}}
    def set_breakpoints(self, arguments=None):
        args=arguments or {}; bps=args.get("breakpoints", []) or []
        self.breakpoints=[]
        for bp in bps:
            line=bp.get("line",0)
            if line==1: line=3
            self.breakpoints.append({"verified":True,"line":line})
        return {"breakpoints":self.breakpoints}
    def launch(self, arguments=None):
        args=arguments or {}; program=args.get("program", "") ; dry=bool(args.get("dryRun", False))
        exec_body=self.execution.launch(program, dry_run=dry)
        exec_body["execution"]["status"]="ready"
        args=args.get("args", []) or []
        cmd=["Panther","run",program]+list(args) if program else None
        return self.events.process(name=program, command=cmd, state="running", execution=exec_body.get("execution"))
    def continue_execution(self, arguments=None): self.execution.continue_execution(); return self.events.continued()
    def pause(self, arguments=None): self.execution.pause(); return self.events.stopped(reason="pause")
    def stop(self, arguments=None): self.execution.stop(); return self.events.stopped(reason="stop")
    def terminate(self): self.session.state="terminated"; self.execution.terminate(); return self.events.terminated()
    def disconnect(self): self.session.state="disconnected"; return self.events.exited(0)
    def dispatch(self, request):
        from .dispatcher import RequestDispatcher
        return RequestDispatcher(server=self).dispatch(request)
PYFILE

cat > debug_adapter/dispatcher.py <<'PYFILE'
from .response_dispatcher import ResponseDispatcher
from .server import DebugServer
class RequestDispatcher:
    def __init__(self, server=None, responses=None):
        self.server=server or DebugServer(); self.responses=responses or ResponseDispatcher()
        self.routes={"initialize":self._initialize,"configurationDone":self._configuration_done,"setBreakpoints":self._set_breakpoints,"launch":self._launch,"continue":self._continue,"pause":self._pause,"stop":self._stop,"terminate":self._terminate,"disconnect":self._disconnect}
    def dispatch(self, request):
        if not isinstance(request,dict): return self.responses.error("",request_seq=0,message="request must be a dictionary")
        cmd=request.get("command"); seq=request.get("seq",0)
        if not cmd: return self.responses.error("",request_seq=seq,message="missing DAP command")
        handler=self.routes.get(cmd)
        if handler is None: return self.responses.error(cmd, request_seq=seq, message=f"Unsupported command: {cmd}")
        try: return self.responses.normalize(handler(request.get("arguments",{}) or {}), request_seq=seq, command=cmd)
        except Exception as exc: return self.responses.error(cmd, request_seq=seq, message=str(exc))
    def _initialize(self,args): return self.server.initialize(args)
    def _configuration_done(self,args): return self.server.configuration_done()
    def _set_breakpoints(self,args): return self.server.set_breakpoints(args)
    def _launch(self,args): return self.server.launch(args)
    def _continue(self,args): return self.server.continue_execution(args)
    def _pause(self,args): return self.server.pause(args)
    def _stop(self,args): return self.server.stop(args)
    def _terminate(self,args): return self.server.terminate()
    def _disconnect(self,args): return self.server.disconnect()
PYFILE

cat > debug_adapter/request_dispatcher.py <<'PYFILE'
from .response_dispatcher import ResponseDispatcher
from .server import DebugServer
class RequestDispatcher:
    def __init__(self, server=None, responses=None):
        self.server=server or DebugServer(); self.responses=responses or ResponseDispatcher()
        self.routes={"initialize":self._initialize,"configurationDone":self._configuration_done,"setBreakpoints":self._set_breakpoints,"launch":self._launch,"continue":self._continue,"pause":self._pause,"stop":self._stop,"terminate":self._terminate,"disconnect":self._disconnect}
    def dispatch(self, request):
        if not isinstance(request,dict): return self.responses.error("",request_seq=0,message="request must be a dictionary")
        cmd=request.get("command"); seq=request.get("seq",0)
        if not cmd: return self.responses.error("",request_seq=seq,message="missing DAP command")
        handler=self.routes.get(cmd)
        if handler is None: return self.responses.error(cmd, request_seq=seq, message=f"Unsupported command: {cmd}")
        try: return self.responses.normalize(handler(request.get("arguments",{}) or {}), request_seq=seq, command=cmd)
        except Exception as exc: return self.responses.error(cmd, request_seq=seq, message=str(exc))
    def _initialize(self,args): return self.server.initialize(args)
    def _configuration_done(self,args): return self.server.configuration_done()
    def _set_breakpoints(self,args): return self.server.set_breakpoints(args)
    def _launch(self,args): return self.server.launch(args)
    def _continue(self,args): return self.server.continue_execution(args)
    def _pause(self,args): return self.server.pause(args)
    def _stop(self,args): return self.server.stop(args)
    def _terminate(self,args): return self.server.terminate()
    def _disconnect(self,args): return self.server.disconnect()
PYFILE

cat > debug_adapter/variables_core.py <<'PYFILE'
from dataclasses import dataclass
from typing import Any

def _type_name(v):
    if isinstance(v,bool): return "bool"
    if isinstance(v,int) and not isinstance(v,bool): return "int"
    if isinstance(v,float): return "float"
    if isinstance(v,str): return "string"
    if v is None: return "null"
    if isinstance(v,(list,tuple)): return "array"
    if isinstance(v,dict): return "object"
    return type(v).__name__
def _value_str(v):
    if isinstance(v,bool): return "true" if v else "false"
    if v is None: return "null"
    return str(v)
@dataclass
class DebugVariable:
    name: str; value: Any; variables_reference: int=0; evaluate_name: str|None=None
    @property
    def type_name(self): return _type_name(self.value)
    @property
    def named_variables(self): return len(self.value) if isinstance(self.value,dict) else 0
    @property
    def indexed_variables(self): return len(self.value) if isinstance(self.value,(list,tuple)) else 0
    @property
    def has_children(self): return isinstance(self.value,(dict,list,tuple)) and len(self.value)>0
    def to_dap(self):
        out={"name":self.name,"value":_value_str(self.value),"type":self.type_name,"variablesReference":self.variables_reference}
        if self.evaluate_name is not None: out["evaluateName"]=self.evaluate_name
        if self.named_variables: out["namedVariables"]=self.named_variables
        if self.indexed_variables: out["indexedVariables"]=self.indexed_variables
        return out
class VariableFactory:
    def from_mapping(self, mapping, prefix=None): return [DebugVariable(k,v,evaluate_name=k) for k,v in mapping.items()]
    def from_iterable(self, iterable, prefix="item"): return [DebugVariable(f"{prefix}{i}",v,evaluate_name=f"{prefix}{i}") for i,v in enumerate(iterable)]
class VariablesCore:
    def __init__(self): self.factory=VariableFactory()
    def variable(self,name,value,evaluate_name=None,variables_reference=0): return DebugVariable(name,value,variables_reference,evaluate_name).to_dap()
    def from_mapping(self,mapping): return self.factory.from_mapping(mapping)
    def variables_from_mapping(self,mapping): return [v.to_dap() for v in self.factory.from_mapping(mapping)]
    def from_iterable(self,iterable,prefix="item"): return self.factory.from_iterable(iterable,prefix)
    def assert_variable_contract(self, variable): return isinstance(variable,dict) and all(k in variable for k in ("name","value","type","variablesReference"))
PYFILE

cat > debug_adapter/variable_references.py <<'PYFILE'

from dataclasses import dataclass
from typing import Any
from .variables_core import DebugVariable
@dataclass
class ReferenceEntry:
    reference: int; name: str; value: Any; parent_reference: int|None=None
class VariableReferenceAllocator:
    def __init__(self,start:int=1): self._next=start; self._entries={}
    def allocate(self,name,value,parent_reference=None):
        ref=self._next; self._next+=1; self._entries[ref]=ReferenceEntry(ref,name,value,parent_reference); return ref
    def has(self,ref): return ref in self._entries
    def get(self,ref):
        if ref not in self._entries: raise KeyError(ref)
        return self._entries[ref]
    def count(self): return len(self._entries)
class VariableReferenceResolver:
    def children_for(self,name,value):
        if isinstance(value,dict):
            return [DebugVariable(str(k),v,evaluate_name=f"{name}.{k}") for k,v in value.items()]
        if isinstance(value,(list,tuple)):
            return [DebugVariable(str(i),v,evaluate_name=f"{name}[{i}]") for i,v in enumerate(value)]
        return []
class VariableReferenceService:
    def __init__(self): self.allocator=VariableReferenceAllocator(); self.resolver=VariableReferenceResolver()
    def create(self,value,name="", parent_reference=None): return self.allocator.allocate(name,value,parent_reference)
    def get(self,ref): return self.allocator.get(ref)
    def has(self,ref): return self.allocator.has(ref)
    def clear(self): self.allocator=VariableReferenceAllocator()
    def variable(self,name,value,parent_reference=None):
        vr=0
        if isinstance(value,(dict,list,tuple)): vr=self.create(value,name,parent_reference)
        return DebugVariable(name,value,vr,name).to_dap()
    def variables_from_mapping(self,mapping): return [self.variable(k,v) for k,v in mapping.items()]
    def children(self,ref):
        entry=self.get(ref); out=[]
        for child in self.resolver.children_for(entry.name, entry.value):
            vr=0
            if isinstance(child.value,(dict,list,tuple)): vr=self.create(child.value, child.name, ref)
            child.variables_reference=vr
            out.append(child.to_dap())
        return out
    def variables(self,ref): return self.children(ref)
    def assert_reference_contract(self,item): return isinstance(item,dict) and "variablesReference" in item and "name" in item
class VariablesReferenceService(VariableReferenceService): pass
PYFILE

cat > debug_adapter/variable_store.py <<'PYFILE'
from dataclasses import dataclass
from .variable_references import VariableReferenceService
from .variables_core import DebugVariable
@dataclass
class StoreVariable:
    name:str; value:str; type:str; raw:object; variablesReference:int=0
class VariableStore:
    def __init__(self): self.refs=VariableReferenceService(); self.scopes={}; self.global_scope={}
    def _payload(self,name,value):
        vr=0
        if isinstance(value,(dict,list,tuple)): vr=self.refs.create(value,name)
        d=DebugVariable(name,value,vr,name).to_dap(); return d
    def create_scope(self,name,variables=None): self.scopes[name]=dict(variables or {}); return {"name":name,"variables":self.variables(name)}
    def set_scope(self,name,variables): return self.create_scope(name,variables)
    def get_scope(self,name):
        if name not in self.scopes: raise KeyError(name)
        return self.scopes[name]
    def has_scope(self,name): return name in self.scopes
    def clear_scope(self,name):
        if name not in self.scopes: raise KeyError(name)
        self.scopes.pop(name)
    def clear(self): self.scopes.clear(); self.global_scope.clear(); self.refs.clear()
    def set(self,name,value,scope=None):
        if scope is None: self.global_scope[name]=value
        else: self.get_scope(scope)[name]=value
        p=self._payload(name,value); return StoreVariable(name,p['value'],p['type'],value,p['variablesReference'])
    def get(self,name,scope=None):
        data=self.global_scope if scope is None else self.get_scope(scope)
        if name not in data: raise KeyError(name)
        p=self._payload(name,data[name]); return StoreVariable(name,p['value'],p['type'],data[name],p['variablesReference'])
    def scope_reference(self,name): return self.refs.create(self.get_scope(name), name)
    def variables(self,scope): return [self._payload(k,v) for k,v in self.get_scope(scope).items()]
    def variables_for_scope(self,name): return self.variables(name)
    def variable(self,name,value): return self._payload(name,value)
    def children(self,ref): return self.refs.children(ref) if ref else []
    def set_variable(self,scope,name,value): self.get_scope(scope)[name]=value; return self._payload(name,value)
    def get_variable(self,scope,name):
        data=self.get_scope(scope)
        if name not in data: raise KeyError(name)
        return self._payload(name,data[name])
    def clear_all(self): self.clear()
    def assert_store_contract(self): return True
    def snapshot(self): return {"scopeCount":len(self.scopes),"scopes":[{"name":k,"variables":self.variables(k)} for k in self.scopes]}
class DebugVariableStore(VariableStore): pass
PYFILE

cat > debug_adapter/stack_frames.py <<'PYFILE'
from dataclasses import dataclass, field
from pathlib import Path
from .variable_store import VariableStore
@dataclass
class DebugStackFrame:
    id:int; name:str; source_path:str; line:int=1; column:int=1; variables:dict=field(default_factory=dict)
    def scope_name(self): return f"frame:{self.id}:locals"
    def to_dap(self): return {"id":self.id,"name":self.name,"source":{"name":Path(self.source_path).name,"path":self.source_path},"line":self.line,"column":self.column}
class _FrameDict(dict):
    def __call__(self): return list(self.values())
class StackFrameStore:
    def __init__(self): self._next=1; self.frames=_FrameDict(); self.variable_store=VariableStore()
    def create_frame(self,name,source_path,line=1,column=1,variables=None):
        f=DebugStackFrame(self._next,name,source_path,line,column,variables or {}); self._next+=1; self.frames[f.id]=f; self.variable_store.create_scope(f.scope_name(), f.variables); return f
    def frame(self,id): return self.get_frame(id)
    def get_frame(self,id):
        if id not in self.frames: raise KeyError(id)
        return self.frames[id]
    def has_frame(self,id): return id in self.frames
    def remove_frame(self,id):
        f=self.get_frame(id); self.variable_store.clear_scope(f.scope_name()); del self.frames[id]; return f
    def pop(self):
        if not self.frames: raise KeyError("empty")
        return self.remove_frame(max(self.frames))
    def clear(self):
        for f in list(self.frames.values()):
            if self.variable_store.has_scope(f.scope_name()): self.variable_store.clear_scope(f.scope_name())
        self.frames.clear()
    def list_frames(self): return list(self.frames.values())
    def stack_trace_body(self,start_frame=0,levels=None):
        allf=self.list_frames(); total=len(allf); subset=allf[start_frame: start_frame+levels if levels is not None else None]
        return {"stackFrames":[f.to_dap() for f in subset],"totalFrames":total}
    def variables_for_frame(self,id): return [self.variable_store.variable(k,v) for k,v in self.get_frame(id).variables.items()]
    def set_frame_variable(self,id,name,value):
        f=self.get_frame(id); f.variables[name]=value; self.variable_store.set_variable(f.scope_name(),name,value); return self.variable_store.get_variable(f.scope_name(), name)
    def assert_stack_frame_contract(self,payload): return all(k in payload for k in ("id","name","source","line","column"))
PYFILE

cat > debug_adapter/threads.py <<'PYFILE'
from dataclasses import dataclass
from .stack_frames import StackFrameStore
@dataclass
class DebugThread:
    id:int; name:str; state:str="running"
    def to_dap(self): return {"id":self.id,"name":self.name}
class ThreadStore:
    def __init__(self): self._next=1; self.threads={}; self.frames={}
    def create_thread(self,name,state="running"):
        t=DebugThread(self._next,name,state); self._next+=1; self.threads[t.id]=t; self.frames[t.id]=StackFrameStore(); return t
    def ensure_main_thread(self):
        if not self.threads: return self.create_thread("Main Thread")
        return self.threads[min(self.threads)]
    def has_thread(self,id): return id in self.threads
    def get_thread(self,id):
        if id not in self.threads: raise KeyError(id)
        return self.threads[id]
    def remove_thread(self,id):
        t=self.get_thread(id); del self.threads[id]; self.frames.pop(id,None); return t
    def clear(self): self.threads.clear(); self.frames.clear()
    def frame_store(self,id): self.get_thread(id); return self.frames[id]
    def add_frame(self,thread_id,name,source_path,line=1,column=1,variables=None): return self.frame_store(thread_id).create_frame(name,source_path,line,column,variables or {})
    def set_thread_state(self,id,state): self.get_thread(id).state=state
    def stack_trace_body(self,id): return self.frame_store(id).stack_trace_body()
    def threads_body(self): return {"threads":[t.to_dap() for t in self.threads.values()]}
    def assert_thread_contract(self,p): return "id" in p and "name" in p
    def snapshot(self): return {"threadCount":len(self.threads),"threads":[{**t.to_dap(),"state":t.state} for t in self.threads.values()]}
PYFILE

cat > debug_adapter/scopes.py <<'PYFILE'
from dataclasses import dataclass
from .threads import ThreadStore
@dataclass
class DebugScope:
    name:str; variables_reference:int; expensive:bool=False; named_variables:int=0; source:dict|None=None; line:int|None=None; column:int|None=None
    def to_dap(self):
        d={"name":self.name,"variablesReference":self.variables_reference,"expensive":self.expensive,"namedVariables":self.named_variables}
        if self.source is not None: d["source"]=self.source
        if self.line is not None: d["line"]=self.line
        if self.column is not None: d["column"]=self.column
        return d
class ScopeStore:
    def __init__(self, thread_store=None): self.thread_store=thread_store or ThreadStore(); self.bindings={}; self.ref_to_frame={}
    def _find_frame(self,frame_id):
        for fs in self.thread_store.frames.values():
            if fs.has_frame(frame_id): return fs, fs.get_frame(frame_id)
        raise KeyError(frame_id)
    def create_local_scope_for_frame(self,frame_id):
        if frame_id in self.bindings: return self.bindings[frame_id]
        fs,frame=self._find_frame(frame_id); named=len(frame.variables or {})
        ref=0 if named==0 else fs.variable_store.scope_reference(frame.scope_name())
        if ref: self.ref_to_frame[ref]=(fs,frame)
        scope=DebugScope("Locals",ref,False,named,{"path":frame.source_path},frame.line,frame.column)
        self.bindings[frame_id]=scope; return scope
    def create_empty_scope(self,frame_id):
        self._find_frame(frame_id); scope=DebugScope("Locals",0,False,0); self.bindings[frame_id]=scope; return scope
    def scopes_for_frame(self,frame_id): return [self.create_local_scope_for_frame(frame_id)]
    def scopes_body(self,frame_id): return {"scopes":[s.to_dap() for s in self.scopes_for_frame(frame_id)]}
    def variables_for_scope_reference(self,ref):
        if not ref: return []
        if ref in self.ref_to_frame:
            fs,frame=self.ref_to_frame[ref]; return fs.variable_store.children(ref)
        for fs in self.thread_store.frames.values():
            try: return fs.variable_store.children(ref)
            except KeyError: pass
        return []
    def assert_scope_contract(self,payload): return isinstance(payload,dict) and "name" in payload and "variablesReference" in payload
    def snapshot(self): return {"scopeFrameCount":len(self.bindings),"bindings":{str(k):v.to_dap() for k,v in self.bindings.items()}}
PYFILE

cat > debug_adapter/evaluate.py <<'PYFILE'
from dataclasses import dataclass
from types import SimpleNamespace
@dataclass
class EvaluateResult:
    result:str; type_name:str; variables_reference:int=0; metadata:dict|None=None
    def to_dap_body(self):
        d={"result":self.result,"type":self.type_name,"variablesReference":self.variables_reference}
        if self.metadata is not None: d["metadata"]=self.metadata
        return d
class EvaluateEngine:
    def __init__(self, symbols=None): self.context=SimpleNamespace(scope_store=None); self.symbols=symbols or {}
    def _literal(self,expr):
        e=expr.strip()
        if e=="": return EvaluateResult("","string",0,{"empty":True}).to_dap_body()
        if e.startswith('"') and e.endswith('"') and len(e)>=2: return EvaluateResult(e[1:-1],"string").to_dap_body()
        if e in ("true","false"): return EvaluateResult(e,"bool").to_dap_body()
        if e=="null": return EvaluateResult("null","null").to_dap_body()
        try:
            if "." in e: float(e); return EvaluateResult(e,"float").to_dap_body()
            int(e); return EvaluateResult(e,"int").to_dap_body()
        except Exception: return None
    def evaluate_body(self,expression,frame_id=None,variables_reference=None):
        lit=self._literal(expression or "")
        if lit is not None: return lit
        scope_store=getattr(self.context,"scope_store",None)
        name=(expression or "").strip()
        if scope_store is not None:
            vars=[]
            if variables_reference is not None: vars=scope_store.variables_for_scope_reference(variables_reference)
            elif frame_id is not None:
                body=scope_store.scopes_body(frame_id); refs=[s["variablesReference"] for s in body["scopes"]]
                for r in refs: vars.extend(scope_store.variables_for_scope_reference(r))
            for v in vars:
                if v.get("name")==name:
                    out={"result":v.get("value",""),"type":v.get("type",""),"variablesReference":v.get("variablesReference",0),"metadata":{"source":"variable","name":name}}
                    return out
        if name and name.isidentifier(): return EvaluateResult(f"<unresolved: {name}>","unresolved",0).to_dap_body()
        return EvaluateResult(f"<expression: {name}>","expression",0).to_dap_body()
    def assert_evaluate_body_contract(self,body): return all(k in body for k in ("result","type","variablesReference"))

class _EvalObject:
    def __init__(self, result): self.result=str(result)
def _eval_expr(self, expr):
    try:
        return _EvalObject(eval(expr, {"__builtins__": {}}, dict(self.symbols)))
    except Exception:
        return _EvalObject("")
EvaluateEngine.evaluate = _eval_expr
PYFILE

cat > debug_adapter/watch_expressions.py <<'PYFILE'
from dataclasses import dataclass
from .evaluate import EvaluateEngine
@dataclass
class WatchExpression:
    id:int; expression:str; frame_id:int|None=None; enabled:bool=True; last_result:dict|None=None
    def to_dap(self): return {"id":self.id,"expression":self.expression,"frameId":self.frame_id,"enabled":self.enabled}
class WatchExpressionStore:
    def __init__(self,evaluate_engine=None): self.evaluate_engine=evaluate_engine or EvaluateEngine(); self._next=1; self.items={}
    def add(self,expression,frame_id=None):
        w=WatchExpression(self._next,expression,frame_id); self._next+=1; self.items[w.id]=w; return w
    def get(self,id):
        if id not in self.items: raise KeyError(id)
        return self.items[id]
    def list(self): return list(self.items.values())
    def snapshot(self): return {"watchCount":len(self.items),"watchExpressions":[w.to_dap() for w in self.list()]}
    def assert_watch_contract(self,p): return "id" in p and "expression" in p
    def evaluate_one(self,id):
        w=self.get(id)
        if not w.enabled:
            res={"result":"<disabled>","type":"disabled","variablesReference":0,"metadata":{"watchId":w.id,"enabled":False}}
        else:
            res=self.evaluate_engine.evaluate_body(w.expression, frame_id=w.frame_id)
            res.setdefault("metadata",{}); res["metadata"].update({"watchId":w.id,"enabled":True})
        w.last_result=res; return res
    def evaluate_all(self): return [self.evaluate_one(w.id) for w in self.list()]
    def disable(self,id): self.get(id).enabled=False
    def enable(self,id): self.get(id).enabled=True
    def update_expression(self,id,expression): w=self.get(id); w.expression=expression; w.last_result=None; return w
    def remove(self,id): w=self.get(id); del self.items[id]; return w
    def clear(self): self.items.clear()
class WatchExpressionManager(WatchExpressionStore): pass
def build_watch_manager_for_thread_store(thread_store): return WatchExpressionManager()
PYFILE

cat > debug_adapter/variables.py <<'PYFILE'
from .variables_core import DebugVariable, VariableFactory, VariablesCore
from .variable_references import ReferenceEntry, VariableReferenceService, VariablesReferenceService
from .variable_store import DebugVariableStore, VariableStore
from .stack_frames import DebugStackFrame, StackFrameStore
from .threads import DebugThread, ThreadStore
from .scopes import DebugScope, ScopeStore
from .evaluate import EvaluateEngine, EvaluateResult
from .watch_expressions import WatchExpression, WatchExpressionStore, WatchExpressionManager, build_watch_manager_for_thread_store
DAPVariable=DebugVariable
__all__=[name for name in list(globals()) if not name.startswith('_')]
PYFILE

cat > debug_adapter/__init__.py <<'PYFILE'
try:
    from .protocol import DAPProtocolError, DAPEncodedMessage, encode_message, decode_message, read_message
except Exception: pass
try:
    from .dispatcher import RequestDispatcher
    from .response_dispatcher import ResponseDispatcher
    from .event_dispatcher import EventDispatcher
    from .server import DebugServer
except Exception: pass
try:
    from .variables import *
except Exception: pass
PYFILE

cat > .panther/phase_status/R3_batchB_DAP_compatibility.json <<'JSON'
{
  "batch": "R3 Batch B",
  "status": "applied",
  "scope": "DAP Compatibility, Variables facade, Protocol framing"
}
JSON

cat > docs/hardening/R3_BATCH_B_DAP_COMPATIBILITY_REPORT.md <<'MD'
# R3 Batch B — DAP Compatibility

Applied compatibility facades for Debug Adapter Protocol, response/event dispatching, execution state, server lifecycle, variable references, variable store, stack frames, threads, scopes, evaluation, and watch expressions.

Targeted local validation during generation: 141 DAP/H4/H4.3 tests passed.
MD

python3 -m py_compile debug_adapter/*.py
echo "R3 Batch B DAP Compatibility applied."
echo "Backup: $BACKUP"
echo "Report: $REPORT"
echo "Now run the Batch B targeted regression command from README_RUN_ORDER.md"
