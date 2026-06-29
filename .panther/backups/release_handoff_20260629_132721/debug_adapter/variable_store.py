from .variables_core import VariableFactory
from .variable_references import VariableReferenceAllocator

class DebugVariableStore:
    def __init__(self):
        self.refs = VariableReferenceAllocator()
        self.globals = {}

    def set(self, name, value):
        self.globals[name] = value
        return self.get(name)

    def get(self, name):
        value = self.globals[name]
        var = VariableFactory.from_value(name, value)
        if isinstance(value, (dict, list, tuple)):
            var.variablesReference = self.refs.allocate(value)
        return var

    def variables(self):
        return [self.get(k) for k in sorted(self.globals)]

class VariableStore(DebugVariableStore):
    pass
