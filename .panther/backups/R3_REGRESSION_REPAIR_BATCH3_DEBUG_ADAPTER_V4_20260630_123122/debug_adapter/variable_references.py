from dataclasses import dataclass
from typing import Any, Optional

@dataclass
class VariableReferenceEntry:
    reference: int
    name: str
    value: Any
    parent_reference: Optional[int] = None

@dataclass
class VariableChild:
    name: str
    value: Any
    evaluate_name: str

class VariableReferenceAllocator:
    def __init__(self, start: int = 1):
        self._next = start
        self._entries = {}

    def allocate(self, name, value=None, parent_reference=None):
        if value is None and not isinstance(name, str):
            value = name
            name = f"ref{self._next}"
        ref = self._next
        self._next += 1
        self._entries[ref] = VariableReferenceEntry(ref, str(name), value, parent_reference)
        return ref

    def has(self, ref):
        return ref in self._entries

    def get(self, ref):
        if ref not in self._entries:
            raise KeyError(ref)
        return self._entries[ref]

    def count(self):
        return len(self._entries)

class VariableReferenceResolver:
    def children_for(self, name, value):
        if isinstance(value, dict):
            return [VariableChild(str(k), v, f"{name}.{k}") for k, v in value.items()]
        if isinstance(value, (list, tuple)):
            return [VariableChild(str(i), v, f"{name}[{i}]") for i, v in enumerate(value)]
        return []

class VariableReferenceService:
    def __init__(self):
        self.allocator = VariableReferenceAllocator()
        self.resolver = VariableReferenceResolver()

    def _type_name(self, value):
        if isinstance(value, bool):
            return "bool"
        if isinstance(value, int) and not isinstance(value, bool):
            return "int"
        if isinstance(value, float):
            return "float"
        if isinstance(value, str):
            return "string"
        if isinstance(value, dict):
            return "object"
        if isinstance(value, (list, tuple)):
            return "array"
        if value is None:
            return "null"
        return type(value).__name__

    def _value_text(self, value):
        if value is True:
            return "true"
        if value is False:
            return "false"
        if value is None:
            return "null"
        return str(value)

    def variable(self, name, value, parent_reference=None):
        ref = 0
        if isinstance(value, (dict, list, tuple)):
            ref = self.allocator.allocate(name, value, parent_reference)
        return {
            "name": str(name),
            "value": self._value_text(value),
            "type": self._type_name(value),
            "variablesReference": ref,
        }

    def variables_from_mapping(self, mapping):
        return [self.variable(k, v) for k, v in dict(mapping or {}).items()]

    def children(self, ref):
        if ref == 0:
            return []
        entry = self.allocator.get(ref)
        return [self.variable(c.name, c.value, ref) for c in self.resolver.children_for(entry.name, entry.value)]

    def assert_reference_contract(self, item):
        return isinstance(item, dict) and {"name", "value", "type", "variablesReference"} <= set(item)

VariableReferenceStore = VariableReferenceService
