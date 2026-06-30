from typing import Optional
from compiler.core.symbol_table import Symbol, SymbolTable

class Scope:
    def __init__(self, parent: Optional["Scope"] = None):
        self.parent = parent
        self.table = SymbolTable()

    def define(self, symbol: Symbol) -> bool:
        return self.table.define(symbol)

    def resolve(self, name: str):
        found = self.table.resolve(name)
        if found:
            return found
        if self.parent:
            return self.parent.resolve(name)
        return None
