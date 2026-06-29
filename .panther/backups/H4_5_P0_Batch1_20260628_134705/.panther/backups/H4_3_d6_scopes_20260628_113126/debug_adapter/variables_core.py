from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Iterable, List, Optional


def _infer_type(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "bool"
    if isinstance(value, int) and not isinstance(value, bool):
        return "int"
    if isinstance(value, float):
        return "float"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        return "array"
    if isinstance(value, tuple):
        return "tuple"
    if isinstance(value, dict):
        return "object"
    return type(value).__name__


def _stringify_value(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, str):
        return value
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def _has_children(value: Any) -> bool:
    return isinstance(value, (dict, list, tuple)) and len(value) > 0


@dataclass(slots=True)
class DebugVariable:
    """
    PantherLang professional debugger variable model.

    This is the base unit that will be consumed by future DAP variables,
    scopes, stack frames, watch expressions, and evaluate responses.
    """

    name: str
    value: Any
    type_name: Optional[str] = None
    variables_reference: int = 0
    evaluate_name: Optional[str] = None
    presentation_hint: Optional[Dict[str, Any]] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if self.type_name is None:
            self.type_name = _infer_type(self.value)

    @property
    def has_children(self) -> bool:
        return _has_children(self.value)

    def to_dap(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "name": str(self.name),
            "value": _stringify_value(self.value),
            "type": str(self.type_name),
            "variablesReference": int(self.variables_reference),
        }

        if self.evaluate_name:
            payload["evaluateName"] = self.evaluate_name

        if self.presentation_hint:
            payload["presentationHint"] = dict(self.presentation_hint)

        if self.metadata:
            payload["metadata"] = dict(self.metadata)

        return payload


class VariableFactory:
    """
    Factory for constructing stable DAP-compatible variable payloads.

    D1 intentionally does not allocate child references yet. That belongs to D2.
    It only creates correct variable objects and supports container detection.
    """

    def create(
        self,
        name: str,
        value: Any,
        variables_reference: int = 0,
        evaluate_name: Optional[str] = None,
        type_name: Optional[str] = None,
        presentation_hint: Optional[Dict[str, Any]] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> DebugVariable:
        return DebugVariable(
            name=name,
            value=value,
            type_name=type_name,
            variables_reference=variables_reference,
            evaluate_name=evaluate_name,
            presentation_hint=presentation_hint,
            metadata=metadata or {},
        )

    def from_mapping(self, values: Dict[str, Any]) -> List[DebugVariable]:
        return [
            self.create(name=str(name), value=value, evaluate_name=str(name))
            for name, value in values.items()
        ]

    def from_iterable(self, values: Iterable[Any], prefix: str = "item") -> List[DebugVariable]:
        return [
            self.create(name=f"{prefix}{index}", value=value, evaluate_name=f"{prefix}{index}")
            for index, value in enumerate(values)
        ]


class VariablesCore:
    """
    Canonical H4.3 Variables Core facade.

    Future H4.3 steps will build on this:
    - D2 variable references
    - D3 variable store
    - D4 stack frames
    - D5 threads
    - D6 scopes
    - D7 evaluate
    """

    def __init__(self, factory: Optional[VariableFactory] = None) -> None:
        self.factory = factory or VariableFactory()

    def variable(
        self,
        name: str,
        value: Any,
        variables_reference: int = 0,
        evaluate_name: Optional[str] = None,
        type_name: Optional[str] = None,
    ) -> Dict[str, Any]:
        return self.factory.create(
            name=name,
            value=value,
            variables_reference=variables_reference,
            evaluate_name=evaluate_name,
            type_name=type_name,
        ).to_dap()

    def variables_from_mapping(self, values: Dict[str, Any]) -> List[Dict[str, Any]]:
        return [item.to_dap() for item in self.factory.from_mapping(values)]

    def variables_from_iterable(self, values: Iterable[Any], prefix: str = "item") -> List[Dict[str, Any]]:
        return [item.to_dap() for item in self.factory.from_iterable(values, prefix=prefix)]

    def assert_variable_contract(self, variable: Dict[str, Any]) -> bool:
        required = {"name", "value", "type", "variablesReference"}
        missing = required.difference(variable.keys())
        if missing:
            raise AssertionError(f"variable missing keys: {sorted(missing)}")
        if not isinstance(variable["variablesReference"], int):
            raise AssertionError("variablesReference must be int")
        return True
