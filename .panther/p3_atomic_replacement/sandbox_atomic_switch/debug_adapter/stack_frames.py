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
