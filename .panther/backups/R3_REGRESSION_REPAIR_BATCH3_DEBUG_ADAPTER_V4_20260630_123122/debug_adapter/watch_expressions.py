from dataclasses import dataclass
from .evaluate import EvaluateEngine

@dataclass
class WatchExpression:
    id: int
    expression: str
    frame_id: int | None = None
    enabled: bool = True
    last_result: dict | None = None

class WatchExpressionStore:
    def __init__(self, evaluate_engine=None):
        self.evaluate_engine = evaluate_engine or EvaluateEngine()
        self._items = []
        self._next = 1

    def add(self, expression, frame_id=None):
        item = WatchExpression(self._next, expression, frame_id)
        self._next += 1
        self._items.append(item)
        return item

    def get(self, item_id):
        for item in self._items:
            if item.id == item_id:
                return item
        raise KeyError(item_id)

    def list(self):
        return list(self._items)

    def evaluate_one(self, item_id):
        item = self.get(item_id)
        result = self.evaluate_engine.evaluate_body(item.expression, frame_id=item.frame_id) if item.enabled else {"result": "<disabled>", "type": "disabled", "variablesReference": 0, "metadata": {}}
        item.last_result = result
        return result

    def evaluate_all(self):
        return [self.evaluate_one(i.id) for i in self._items]

    def disable(self, item_id):
        self.get(item_id).enabled = False

    def enable(self, item_id):
        self.get(item_id).enabled = True

    def update_expression(self, item_id, expression):
        item = self.get(item_id)
        item.expression = expression
        item.last_result = None
        return item

    def remove(self, item_id):
        for idx, item in enumerate(self._items):
            if item.id == item_id:
                return self._items.pop(idx)
        raise KeyError(item_id)

    def clear(self):
        self._items.clear()

    def snapshot(self):
        return {"watchCount": len(self._items), "watchExpressions": [{"id": i.id, "expression": i.expression, "enabled": i.enabled} for i in self._items]}

    def assert_watch_contract(self, item):
        return isinstance(item, dict) and {"id", "expression", "enabled"} <= set(item)

class WatchExpressionManager:
    def __init__(self, store):
        self.store = store

def build_watch_manager_for_thread_store(thread_store):
    return WatchExpressionManager(WatchExpressionStore())
