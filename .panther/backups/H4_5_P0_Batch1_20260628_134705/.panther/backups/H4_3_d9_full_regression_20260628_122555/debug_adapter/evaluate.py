from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Optional

from .scopes import ScopeStore
from .threads import ThreadStore


@dataclass(slots=True)
class EvaluateResult:
    """
    PantherLang professional DAP Evaluate result.

    DAP EvaluateResponse body commonly includes:
    - result
    - type
    - variablesReference
    - namedVariables
    - indexedVariables
    """

    result: str
    type_name: str = "string"
    variables_reference: int = 0
    named_variables: Optional[int] = None
    indexed_variables: Optional[int] = None
    presentation_hint: Optional[Dict[str, Any]] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dap_body(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "result": str(self.result),
            "type": str(self.type_name),
            "variablesReference": int(self.variables_reference),
        }

        if self.named_variables is not None:
            payload["namedVariables"] = int(self.named_variables)

        if self.indexed_variables is not None:
            payload["indexedVariables"] = int(self.indexed_variables)

        if self.presentation_hint:
            payload["presentationHint"] = dict(self.presentation_hint)

        if self.metadata:
            payload["metadata"] = dict(self.metadata)

        return payload


class EvaluateContext:
    """
    Evaluation context used by H4.3 D7.

    It can resolve variables from:
    - explicit variablesReference
    - frameId through ScopeStore
    - plain synthetic expression literals
    """

    def __init__(self, scope_store: Optional[ScopeStore] = None) -> None:
        self.scope_store = scope_store or ScopeStore(thread_store=ThreadStore())

    def variables_for_frame(self, frame_id: int) -> Dict[str, Dict[str, Any]]:
        body = self.scope_store.scopes_body(frame_id)
        if not body["scopes"]:
            return {}

        variables: Dict[str, Dict[str, Any]] = {}
        for scope in body["scopes"]:
            ref = scope["variablesReference"]
            for item in self.scope_store.variables_for_scope_reference(ref):
                variables[item["name"]] = item
        return variables

    def variables_for_reference(self, variables_reference: int) -> Dict[str, Dict[str, Any]]:
        return {
            item["name"]: item
            for item in self.scope_store.variables_for_scope_reference(int(variables_reference))
        }


class EvaluateEngine:
    """
    H4.3 D7 Evaluate Engine.

    This is intentionally safe and deterministic:
    - No Python eval.
    - No shell execution.
    - No arbitrary code execution.
    - Supports variable lookup, literals, and simple debug metadata.
    """

    def __init__(self, context: Optional[EvaluateContext] = None) -> None:
        self.context = context or EvaluateContext()

    def evaluate(
        self,
        expression: str,
        frame_id: Optional[int] = None,
        variables_reference: Optional[int] = None,
        context: str = "watch",
    ) -> EvaluateResult:
        expr = str(expression).strip()

        if expr == "":
            return EvaluateResult(
                result="",
                type_name="string",
                variables_reference=0,
                metadata={"context": context, "empty": True},
            )

        if variables_reference is not None and int(variables_reference) > 0:
            variables = self.context.variables_for_reference(int(variables_reference))
            if expr in variables:
                return self._from_variable(variables[expr], context=context)
            return EvaluateResult(
                result=f"<unresolved: {expr}>",
                type_name="unresolved",
                variables_reference=0,
                metadata={"context": context, "variablesReference": int(variables_reference)},
            )

        if frame_id is not None:
            variables = self.context.variables_for_frame(int(frame_id))
            if expr in variables:
                return self._from_variable(variables[expr], context=context)
            return EvaluateResult(
                result=f"<unresolved: {expr}>",
                type_name="unresolved",
                variables_reference=0,
                metadata={"context": context, "frameId": int(frame_id)},
            )

        return self._literal(expr, context=context)

    def _from_variable(self, variable: Dict[str, Any], context: str = "watch") -> EvaluateResult:
        named = None
        indexed = None

        var_type = variable.get("type", "string")
        var_ref = int(variable.get("variablesReference", 0))

        if var_ref > 0:
            if var_type == "object":
                named = 1
            elif var_type in {"array", "tuple"}:
                indexed = 1

        return EvaluateResult(
            result=str(variable.get("value", "")),
            type_name=str(var_type),
            variables_reference=var_ref,
            named_variables=named,
            indexed_variables=indexed,
            metadata={
                "context": context,
                "source": "variable",
                "name": variable.get("name"),
            },
        )

    def _literal(self, expr: str, context: str = "watch") -> EvaluateResult:
        lowered = expr.lower()

        if lowered in {"true", "false"}:
            return EvaluateResult(
                result=lowered,
                type_name="bool",
                variables_reference=0,
                metadata={"context": context, "source": "literal"},
            )

        if lowered == "null":
            return EvaluateResult(
                result="null",
                type_name="null",
                variables_reference=0,
                metadata={"context": context, "source": "literal"},
            )

        try:
            int(expr)
            return EvaluateResult(
                result=expr,
                type_name="int",
                variables_reference=0,
                metadata={"context": context, "source": "literal"},
            )
        except ValueError:
            pass

        try:
            float(expr)
            return EvaluateResult(
                result=expr,
                type_name="float",
                variables_reference=0,
                metadata={"context": context, "source": "literal"},
            )
        except ValueError:
            pass

        if (expr.startswith('"') and expr.endswith('"')) or (expr.startswith("'") and expr.endswith("'")):
            return EvaluateResult(
                result=expr[1:-1],
                type_name="string",
                variables_reference=0,
                metadata={"context": context, "source": "literal"},
            )

        return EvaluateResult(
            result=f"<expression: {expr}>",
            type_name="expression",
            variables_reference=0,
            metadata={"context": context, "source": "synthetic"},
        )

    def evaluate_body(
        self,
        expression: str,
        frame_id: Optional[int] = None,
        variables_reference: Optional[int] = None,
        context: str = "watch",
    ) -> Dict[str, Any]:
        return self.evaluate(
            expression=expression,
            frame_id=frame_id,
            variables_reference=variables_reference,
            context=context,
        ).to_dap_body()

    def assert_evaluate_body_contract(self, body: Dict[str, Any]) -> bool:
        required = {"result", "type", "variablesReference"}
        missing = required.difference(body.keys())
        if missing:
            raise AssertionError(f"evaluate body missing keys: {sorted(missing)}")
        if not isinstance(body["variablesReference"], int):
            raise AssertionError("evaluate variablesReference must be int")
        return True


class DebugEvaluateEngine(EvaluateEngine):
    """Public professional alias used by later H4.3 phases."""
    pass
