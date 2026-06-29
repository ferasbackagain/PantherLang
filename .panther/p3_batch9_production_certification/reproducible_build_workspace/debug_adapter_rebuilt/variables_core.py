from dataclasses import dataclass
from typing import Any

@dataclass
class DebugVariable:
    name: str
    value: str
    type: str = "string"
    variablesReference: int = 0

class VariableFactory:
    @staticmethod
    def from_value(name: str, value: Any):
        if isinstance(value, bool):
            t = "boolean"
        elif isinstance(value, int):
            t = "number"
        elif isinstance(value, float):
            t = "number"
        elif isinstance(value, (dict, list, tuple)):
            t = "object"
        else:
            t = "string"
        return DebugVariable(name=name, value=str(value), type=t)

class VariablesCore:
    def make(self, name: str, value: Any):
        return VariableFactory.from_value(name, value)
