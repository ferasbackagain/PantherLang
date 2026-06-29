from dataclasses import dataclass

@dataclass
class EvaluateResult:
    result: str
    type: str = "string"
    variablesReference: int = 0

class EvaluateEngine:
    def __init__(self, variables=None):
        self.variables = variables or {}

    def evaluate(self, expression):
        if expression in self.variables:
            value = self.variables[expression]
            return EvaluateResult(result=str(value), type=type(value).__name__)
        try:
            value = eval(expression, {"__builtins__": {}}, dict(self.variables))
            return EvaluateResult(result=str(value), type=type(value).__name__)
        except Exception as exc:
            return EvaluateResult(result=f"error: {exc}", type="error")
