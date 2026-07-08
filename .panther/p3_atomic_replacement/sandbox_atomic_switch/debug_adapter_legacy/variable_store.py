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
