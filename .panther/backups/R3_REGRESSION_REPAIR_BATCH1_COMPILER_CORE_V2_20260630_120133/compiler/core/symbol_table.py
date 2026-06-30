from dataclasses import dataclass, field
from typing import Dict, Optional

@dataclass
class Symbol:
    name: str
    kind: str
    type_name: str = ""
    metadata: dict = field(default_factory=dict)

class SymbolTable:
    def __init__(self):
        self.symbols: Dict[str, Symbol] = {}

    def define(self, symbol: Symbol) -> bool:
        if symbol.name in self.symbols:
            return False
        self.symbols[symbol.name] = symbol
        return True

    def resolve(self, name: str) -> Optional[Symbol]:
        return self.symbols.get(name)

    def all_symbols(self):
        return list(self.symbols.values())
