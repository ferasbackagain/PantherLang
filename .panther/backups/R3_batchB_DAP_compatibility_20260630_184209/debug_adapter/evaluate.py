from __future__ import annotations

from dataclasses import dataclass, field
from types import SimpleNamespace
from typing import Any
import ast
import operator


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

    def _type_name(self, value: Any):
        if isinstance(value, bool): return "bool"
        if isinstance(value, int) and not isinstance(value, bool): return "int"
        if isinstance(value, float): return "float"
        if isinstance(value, str): return "string"
        if isinstance(value, dict): return "object"
        if isinstance(value, (list, tuple)): return "array"
        if value is None: return "null"
        return type(value).__name__

    def _value_text(self, value: Any):
        if value is True: return "true"
        if value is False: return "false"
        if value is None: return "null"
        return str(value)

    def _body_for_value(self, value: Any, metadata=None):
        metadata = dict(metadata or {})
        ref = 1 if isinstance(value, (dict, list, tuple)) else 0
        return {"result": self._value_text(value), "type": self._type_name(value), "variablesReference": ref, "metadata": metadata}

    def _lookup_frame_variable(self, expression, frame_id=None, variables_reference=None):
        scopes = getattr(self.context, "scope_store", None)
        if scopes is None:
            return None
        try:
            source = None
            if variables_reference is not None:
                source = scopes.variables_for_scope_reference(variables_reference)
            elif frame_id is not None:
                source = scopes.variables_for_frame(frame_id)
            if source is not None:
                for item in source:
                    if item.get("name") == expression:
                        return {"result": item.get("value", ""), "type": item.get("type", "string"), "variablesReference": item.get("variablesReference", 0), "metadata": {"source": "variable", "name": expression}}
        except Exception:
            return None
        return None

    def _safe_eval_arithmetic(self, expression: str):
        allowed_binops = {ast.Add: operator.add, ast.Sub: operator.sub, ast.Mult: operator.mul, ast.Div: operator.truediv, ast.FloorDiv: operator.floordiv, ast.Mod: operator.mod}
        allowed_unary = {ast.UAdd: operator.pos, ast.USub: operator.neg}
        def eval_node(node):
            if isinstance(node, ast.Expression): return eval_node(node.body)
            if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)): return node.value
            if isinstance(node, ast.Name) and node.id in self.variables and isinstance(self.variables[node.id], (int, float)): return self.variables[node.id]
            if isinstance(node, ast.BinOp) and type(node.op) in allowed_binops: return allowed_binops[type(node.op)](eval_node(node.left), eval_node(node.right))
            if isinstance(node, ast.UnaryOp) and type(node.op) in allowed_unary: return allowed_unary[type(node.op)](eval_node(node.operand))
            raise ValueError("unsupported expression")
        return eval_node(ast.parse(expression, mode="eval"))

    def evaluate_body(self, expression, frame_id=None, variables_reference=None):
        expression = expression or ""
        if expression == "":
            return {"result": "", "type": "string", "variablesReference": 0, "metadata": {"empty": True}}
        frame_value = self._lookup_frame_variable(expression, frame_id, variables_reference)
        if frame_value is not None:
            return frame_value
        if expression in self.variables:
            return self._body_for_value(self.variables[expression], {"source": "variable", "name": expression})
        if expression.isdigit():
            return {"result": expression, "type": "int", "variablesReference": 0, "metadata": {"source": "literal"}}
        try:
            float(expression)
            if "." in expression:
                return {"result": expression, "type": "float", "variablesReference": 0, "metadata": {"source": "literal"}}
        except Exception:
            pass
        if expression in ("true", "false"):
            return {"result": expression, "type": "bool", "variablesReference": 0, "metadata": {"source": "literal"}}
        if expression == "null":
            return {"result": "null", "type": "null", "variablesReference": 0, "metadata": {"source": "literal"}}
        if len(expression) >= 2 and expression[0] == expression[-1] == '"':
            return {"result": expression[1:-1], "type": "string", "variablesReference": 0, "metadata": {"source": "literal"}}
        try:
            result = self._safe_eval_arithmetic(expression)
            result_text = str(int(result)) if isinstance(result, float) and result.is_integer() else str(result)
            result_type = "int" if result_text.lstrip("-").isdigit() else "float"
            return {"result": result_text, "type": result_type, "variablesReference": 0, "metadata": {"source": "safe_arithmetic"}}
        except Exception:
            pass
        if frame_id is not None or variables_reference is not None:
            return {"result": f"<unresolved: {expression}>", "type": "unresolved", "variablesReference": 0, "metadata": {"safe": True}}
        return {"result": f"<expression: {expression}>", "type": "expression", "variablesReference": 0, "metadata": {"safe": True}}

    def evaluate(self, expression):
        body = self.evaluate_body(expression)
        return EvaluateResult(body["result"], body["type"], body["variablesReference"], body.get("metadata", {}))

    def assert_evaluate_body_contract(self, body):
        return isinstance(body, dict) and {"result", "type", "variablesReference"} <= set(body)
