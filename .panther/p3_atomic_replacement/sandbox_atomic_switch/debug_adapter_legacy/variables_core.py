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
