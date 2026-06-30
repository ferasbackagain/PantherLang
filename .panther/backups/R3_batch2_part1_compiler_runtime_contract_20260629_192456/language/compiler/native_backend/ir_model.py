from __future__ import annotations
from dataclasses import dataclass, field
from typing import Any, Dict, List
@dataclass(slots=True)
class NativeInstruction:
    opcode: str; operands: List[Any]=field(default_factory=list)
    def validate(self)->None:
        if not self.opcode or not isinstance(self.opcode,str): raise ValueError("instruction opcode must be non-empty")
@dataclass(slots=True)
class NativeFunction:
    name: str; instructions: List[NativeInstruction]=field(default_factory=list); exports: bool=False
    def validate(self)->None:
        if not self.name or not self.name.replace("_","").isalnum(): raise ValueError("invalid native function name")
        for i in self.instructions: i.validate()
@dataclass(slots=True)
class NativeModule:
    name: str; functions: List[NativeFunction]=field(default_factory=list); metadata: Dict[str,Any]=field(default_factory=dict)
    def validate(self)->None:
        if not self.name: raise ValueError("module name is required")
        if not self.functions: raise ValueError("native module must contain at least one function")
        for f in self.functions: f.validate()
