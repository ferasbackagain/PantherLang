from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from .evaluate import EvaluateEngine, EvaluateResult
from .scopes import ScopeStore
from .threads import ThreadStore


@dataclass(slots=True)
class WatchExpression:
    """
    PantherLang professional debugger watch expression.

    Watch expressions are client-managed expressions that are repeatedly
    evaluated against the active frame / scope context.
    """

    id: int
    expression: str
    frame_id: Optional[int] = None
    variables_reference: Optional[int] = None
    context: str = "watch"
    enabled: bool = True
    last_result: Optional[Dict[str, Any]] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "id": int(self.id),
            "expression": str(self.expression),
            "frameId": self.frame_id,
            "variablesReference": self.variables_reference,
            "context": str(self.context),
            "enabled": bool(self.enabled),
            "lastResult": self.last_result,
        }
        if self.metadata:
            payload["metadata"] = dict(self.metadata)
        return payload


class WatchExpressionStore:
    """
    H4.3 D8 Watch Expression Store.

    Responsibilities:
    - Register watch expressions.
    - Evaluate watch expressions through D7 EvaluateEngine.
    - Preserve lastResult for debugger UI refreshes.
    - Support enable/disable/delete/list operations.
    """

    def __init__(self, evaluate_engine: Optional[EvaluateEngine] = None) -> None:
        self.evaluate_engine = evaluate_engine or EvaluateEngine()
        self._items: Dict[int, WatchExpression] = {}
        self._next_id = 1

    def add(
        self,
        expression: str,
        frame_id: Optional[int] = None,
        variables_reference: Optional[int] = None,
        context: str = "watch",
        enabled: bool = True,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> WatchExpression:
        item = WatchExpression(
            id=self._next_id,
            expression=str(expression),
            frame_id=frame_id,
            variables_reference=variables_reference,
            context=context,
            enabled=enabled,
            metadata=dict(metadata or {}),
        )
        self._next_id += 1
        self._items[item.id] = item
        return item

    def get(self, watch_id: int) -> WatchExpression:
        wid = int(watch_id)
        if wid not in self._items:
            raise KeyError(f"unknown watch expression id: {wid}")
        return self._items[wid]

    def remove(self, watch_id: int) -> WatchExpression:
        item = self.get(watch_id)
        del self._items[item.id]
        return item

    def clear(self) -> None:
        self._items.clear()

    def list(self) -> List[WatchExpression]:
        return [self._items[key] for key in sorted(self._items.keys())]

    def enable(self, watch_id: int) -> WatchExpression:
        item = self.get(watch_id)
        item.enabled = True
        return item

    def disable(self, watch_id: int) -> WatchExpression:
        item = self.get(watch_id)
        item.enabled = False
        return item

    def update_expression(self, watch_id: int, expression: str) -> WatchExpression:
        item = self.get(watch_id)
        item.expression = str(expression)
        item.last_result = None
        return item

    def evaluate_one(self, watch_id: int) -> Dict[str, Any]:
        item = self.get(watch_id)

        if not item.enabled:
            result = EvaluateResult(
                result="<disabled>",
                type_name="disabled",
                variables_reference=0,
                metadata={"watchId": item.id, "enabled": False},
            ).to_dap_body()
            item.last_result = result
            return result

        result = self.evaluate_engine.evaluate_body(
            expression=item.expression,
            frame_id=item.frame_id,
            variables_reference=item.variables_reference,
            context=item.context,
        )
        result.setdefault("metadata", {})
        result["metadata"]["watchId"] = item.id
        item.last_result = result
        return result

    def evaluate_all(self) -> List[Dict[str, Any]]:
        return [
            self.evaluate_one(item.id)
            for item in self.list()
        ]

    def snapshot(self) -> Dict[str, Any]:
        return {
            "watchCount": len(self._items),
            "watchExpressions": [item.to_dict() for item in self.list()],
        }

    def assert_watch_contract(self, item: Dict[str, Any]) -> bool:
        required = {"id", "expression", "context", "enabled", "lastResult"}
        missing = required.difference(item.keys())
        if missing:
            raise AssertionError(f"watch expression missing keys: {sorted(missing)}")
        if not isinstance(item["id"], int):
            raise AssertionError("watch id must be int")
        if not isinstance(item["enabled"], bool):
            raise AssertionError("watch enabled must be bool")
        return True


class WatchExpressionManager(WatchExpressionStore):
    """Public professional alias used by later H4.3 phases."""
    pass


def build_watch_manager_for_thread_store(thread_store: Optional[ThreadStore] = None) -> WatchExpressionManager:
    """
    Convenience builder for integrated debugger sessions.
    """
    scopes = ScopeStore(thread_store=thread_store or ThreadStore())
    engine = EvaluateEngine()
    engine.context.scope_store = scopes
    return WatchExpressionManager(evaluate_engine=engine)
