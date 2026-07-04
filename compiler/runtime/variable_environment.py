from __future__ import annotations

from typing import Any, Callable


class VariableError(Exception):
    pass


class UndefinedVariableError(VariableError):
    def __init__(self, name: str) -> None:
        self.name = name
        super().__init__(f"Undefined variable: {name}")


class RedeclarationError(VariableError):
    def __init__(self, name: str) -> None:
        self.name = name
        super().__init__(f"Variable already declared: {name}")


class VariableEnvironment:
    def __init__(self, parent: VariableEnvironment | None = None) -> None:
        self._variables: dict[str, Any] = {}
        self._functions: dict[str, Any] = {}
        self._types: dict[str, Any] = {}
        self._parent: VariableEnvironment | None = parent

    def define(self, name: str, value: Any = None) -> None:
        if name in self._variables:
            raise RedeclarationError(name)
        self._variables[name] = value

    def lookup(self, name: str) -> Any:
        if name in self._variables:
            return self._variables[name]
        if self._parent is not None:
            return self._parent.lookup(name)
        raise UndefinedVariableError(name)

    def assign(self, name: str, value: Any) -> None:
        if name in self._variables:
            self._variables[name] = value
            return
        if self._parent is not None:
            self._parent.assign(name, value)
            return
        raise UndefinedVariableError(name)

    def has(self, name: str) -> bool:
        if name in self._variables:
            return True
        if self._parent is not None:
            return self._parent.has(name)
        return False

    def snapshot(self) -> dict[str, Any]:
        result = {}
        if self._parent is not None:
            result.update(self._parent.snapshot())
        result.update(self._variables)
        return result

    def define_type(self, name: str, type_def: Any) -> None:
        self._types[name] = type_def

    def lookup_type(self, name: str) -> Any:
        if name in self._types:
            return self._types[name]
        if self._parent is not None:
            return self._parent.lookup_type(name)
        raise UndefinedVariableError(f"Undefined type: {name}")

    def has_type(self, name: str) -> bool:
        if name in self._types:
            return True
        if self._parent is not None:
            return self._parent.has_type(name)
        return False

    def _new_child(self) -> VariableEnvironment:
        child = VariableEnvironment(parent=self)
        child._functions = dict(self._functions)
        child._types = dict(self._types)
        return child

    def define_function(self, name: str, func: Any) -> None:
        self._functions[name] = func

    def lookup_function(self, name: str) -> Any:
        if name not in self._functions:
            raise UndefinedVariableError(f"Undefined function: {name}")
        return self._functions[name]

    def has_function(self, name: str) -> bool:
        return name in self._functions

    @classmethod
    def create_default(cls) -> VariableEnvironment:
        env = cls()
        _register_stdlib(env)
        return env


def _register_stdlib(env: VariableEnvironment) -> None:
    try:
        from compiler.stdlib import get_stdlib_functions
        for name, fn in get_stdlib_functions().items():
            env._functions[name] = fn.fn
    except ImportError:
        pass
