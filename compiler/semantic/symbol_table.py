from __future__ import annotations

from typing import Any

from .scope import Scope, SymbolKind


class SymbolTable:
    def __init__(self) -> None:
        self.global_scope = Scope()
        self._current = self.global_scope

    @property
    def current(self) -> Scope:
        return self._current

    def enter_scope(self) -> Scope:
        child = self._current.new_child()
        self._current = child
        return child

    def exit_scope(self) -> None:
        if self._current.parent is not None:
            self._current = self._current.parent

    def declare(
        self, name: str, kind: SymbolKind, location: Any = None
    ) -> None:
        self._current.declare(name, kind, location)

    def lookup(self, name: str) -> Any:
        return self._current.lookup(name)

    def lookup_local(self, name: str) -> Any:
        return self._current.lookup_local(name)

    def create_function_scope(
        self, name: str, params: tuple[str, ...], declare: bool = True
    ) -> Scope:
        if declare:
            self.declare(name, SymbolKind.FUNCTION)
        fn_scope = self.enter_scope()
        for param in params:
            fn_scope.declare(param, SymbolKind.PARAMETER)
        return fn_scope
