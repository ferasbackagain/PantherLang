
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
