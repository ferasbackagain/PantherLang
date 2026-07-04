from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Any


class SymbolKind(Enum):
    VARIABLE = auto()
    FUNCTION = auto()
    TYPE = auto()
    MODULE = auto()
    PARAMETER = auto()


@dataclass
class Symbol:
    name: str = ""
    kind: SymbolKind = SymbolKind.VARIABLE
    location: Any = None
    type_ref: Any = None


@dataclass
class Scope:
    parent: Scope | None = None
    symbols: dict[str, Symbol] = field(default_factory=dict)
    children: list[Scope] = field(default_factory=list)

    def declare(self, name: str, kind: SymbolKind, location: Any = None) -> Symbol:
        if name in self.symbols:
            existing = self.symbols[name]
            raise DuplicateSymbolError(name, existing.location, location)
        sym = Symbol(name=name, kind=kind, location=location)
        self.symbols[name] = sym
        return sym

    def lookup(self, name: str) -> Symbol | None:
        if name in self.symbols:
            return self.symbols[name]
        if self.parent is not None:
            return self.parent.lookup(name)
        return None

    def lookup_local(self, name: str) -> Symbol | None:
        return self.symbols.get(name)

    def new_child(self) -> Scope:
        child = Scope(parent=self)
        self.children.append(child)
        return child


class DuplicateSymbolError(Exception):
    def __init__(self, name: str, first: Any, second: Any) -> None:
        self.name = name
        self.first = first
        self.second = second
        super().__init__(f"Duplicate symbol '{name}'")
