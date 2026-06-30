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
