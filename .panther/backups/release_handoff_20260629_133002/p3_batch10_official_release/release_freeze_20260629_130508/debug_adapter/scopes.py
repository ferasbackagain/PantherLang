from dataclasses import dataclass

@dataclass
class DebugScope:
    name: str
    variablesReference: int
    expensive: bool = False

class ScopeStore:
    def __init__(self):
        self._scopes = []

    def add(self, name, variablesReference, expensive=False):
        scope = DebugScope(name, variablesReference, expensive)
        self._scopes.append(scope)
        return scope

    def list(self):
        return list(self._scopes)
