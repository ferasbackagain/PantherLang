from dataclasses import dataclass, field
from types import SimpleNamespace

@dataclass
class EvaluateResult:
    result: str
    type_name: str = "string"
    variables_reference: int = 0
    metadata: dict = field(default_factory=dict)

    def to_dap_body(self):
        return {
            "result": self.result,
            "type": self.type_name,
            "variablesReference": self.variables_reference,
            "metadata": self.metadata,
        }

class EvaluateEngine:
    def __init__(self, variables=None):
        self.variables = dict(variables or {})
        self.context = SimpleNamespace(scope_store=None)

    def evaluate_body(self, expression, frame_id=None, variables_reference=None):
        expression = expression or ""
        if expression in self.variables:
            value = self.variables[expression]
            return {"result": str(value), "type": type(value).__name__, "variablesReference": 0, "metadata": {"source": "variable"}}
        if expression.isdigit():
            return {"result": expression, "type": "int", "variablesReference": 0, "metadata": {"source": "literal"}}
        if expression in ("true", "false"):
            return {"result": expression, "type": "bool", "variablesReference": 0, "metadata": {"source": "literal"}}
        return {"result": f"<expression: {expression}>", "type": "expression", "variablesReference": 0, "metadata": {"safe": True}}

    def evaluate(self, expression):
        body = self.evaluate_body(expression)
        return EvaluateResult(body["result"], body["type"], body["variablesReference"], body.get("metadata", {}))

    def assert_evaluate_body_contract(self, body):
        return isinstance(body, dict) and {"result", "type", "variablesReference"} <= set(body)
