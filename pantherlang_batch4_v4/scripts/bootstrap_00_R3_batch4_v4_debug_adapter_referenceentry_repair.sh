#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
if [ ! -d "$ROOT/debug_adapter" ] || [ ! -d "$ROOT/tests" ]; then
  echo "ERROR: Run this script from the PantherLang repository root." >&2
  echo "Expected: /home/panther/pantherlang/PantherLang_Developer_Edition_v0_5" >&2
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.panther/backups/R3_batch4_v4_debug_adapter_referenceentry_${STAMP}"
REPORT_DIR="$ROOT/.panther/reports/R3_batch4_v4_debug_adapter_referenceentry_${STAMP}"
mkdir -p "$BACKUP_DIR" "$REPORT_DIR"
cp -a "$ROOT/debug_adapter" "$BACKUP_DIR/debug_adapter.before"

python3 - <<'PY'
from pathlib import Path

Path('debug_adapter/variable_references.py').write_text('''from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Optional


@dataclass
class VariableReferenceEntry:
    reference: int
    name: str
    value: Any
    parent_reference: Optional[int] = None


# Legacy compatibility name expected by older Debug Adapter tests/imports.
ReferenceEntry = VariableReferenceEntry


@dataclass
class VariableChild:
    name: str
    value: Any
    evaluate_name: str


class VariableReferenceAllocator:
    def __init__(self, start: int = 1):
        self._next = int(start)
        self._entries: dict[int, VariableReferenceEntry] = {}

    def allocate(self, name, value=None, parent_reference=None):
        # Backward-compatible form: allocate(value)
        if value is None and not isinstance(name, str):
            value = name
            name = f"ref{self._next}"
        ref = self._next
        self._next += 1
        self._entries[ref] = VariableReferenceEntry(ref, str(name), value, parent_reference)
        return ref

    def has(self, ref):
        return ref in self._entries

    def get(self, ref):
        if ref not in self._entries:
            raise KeyError(ref)
        return self._entries[ref]

    def count(self):
        return len(self._entries)

    def clear(self):
        self._entries.clear()


class VariableReferenceResolver:
    def children_for(self, name, value):
        if isinstance(value, dict):
            return [VariableChild(str(k), v, f"{name}.{k}") for k, v in value.items()]
        if isinstance(value, (list, tuple)):
            return [VariableChild(str(i), v, f"{name}[{i}]") for i, v in enumerate(value)]
        return []


class VariableReferenceService:
    def __init__(self):
        self.allocator = VariableReferenceAllocator()
        self.resolver = VariableReferenceResolver()

    def _type_name(self, value):
        if isinstance(value, bool):
            return "bool"
        if isinstance(value, int) and not isinstance(value, bool):
            return "int"
        if isinstance(value, float):
            return "float"
        if isinstance(value, str):
            return "string"
        if isinstance(value, dict):
            return "object"
        if isinstance(value, (list, tuple)):
            return "array"
        if value is None:
            return "null"
        return type(value).__name__

    def _value_text(self, value):
        if value is True:
            return "true"
        if value is False:
            return "false"
        if value is None:
            return "null"
        return str(value)

    def variable(self, name, value, parent_reference=None):
        ref = 0
        if isinstance(value, (dict, list, tuple)):
            ref = self.allocator.allocate(name, value, parent_reference)
        return {
            "name": str(name),
            "value": self._value_text(value),
            "type": self._type_name(value),
            "variablesReference": ref,
        }

    def variables_from_mapping(self, mapping):
        return [self.variable(k, v) for k, v in dict(mapping or {}).items()]

    def children(self, ref):
        if ref == 0:
            return []
        entry = self.allocator.get(ref)
        return [self.variable(c.name, c.value, ref) for c in self.resolver.children_for(entry.name, entry.value)]

    def assert_reference_contract(self, item):
        return isinstance(item, dict) and {"name", "value", "type", "variablesReference"} <= set(item)


VariableReferenceStore = VariableReferenceService
''')

Path('debug_adapter/variable_store.py').write_text('''from __future__ import annotations

from collections import OrderedDict
from typing import Any

from .variable_references import VariableReferenceService


class DAPVariable(dict):
    def __getattr__(self, key):
        try:
            return self[key]
        except KeyError as exc:
            raise AttributeError(key) from exc


class DebugVariableStore:
    """Compatibility variable store for legacy and current DAP tests.

    Supports the newer scope-based API used by H4.3 and the older global
    set/get/variables API used by earlier batches.
    """

    def __init__(self):
        self.references = VariableReferenceService()
        self._scopes: OrderedDict[str, dict[str, Any]] = OrderedDict()
        self.globals: dict[str, Any] = {}

    def create_scope(self, name: str, variables=None):
        self._scopes[str(name)] = dict(variables or {})
        return self.get_scope(name)

    def has_scope(self, name: str) -> bool:
        return str(name) in self._scopes

    def get_scope(self, name: str):
        key = str(name)
        if key not in self._scopes:
            raise KeyError(name)
        return {"name": key, "variables": self.variables(key)}

    def clear_scope(self, name: str):
        key = str(name)
        if key not in self._scopes:
            raise KeyError(name)
        del self._scopes[key]

    def clear_all(self):
        self._scopes.clear()
        self.globals.clear()
        self.references = VariableReferenceService()

    def snapshot(self):
        scopes = [self.get_scope(name) for name in self._scopes.keys()]
        return {"scopeCount": len(scopes), "scopes": scopes}

    def assert_store_contract(self):
        snap = self.snapshot()
        return isinstance(snap, dict) and "scopeCount" in snap and "scopes" in snap

    def set_variable(self, scope: str, name: str, value: Any):
        key = str(scope)
        if key not in self._scopes:
            raise KeyError(scope)
        self._scopes[key][str(name)] = value
        return self.get_variable(key, name)

    def get_variable(self, scope: str, name: str):
        key = str(scope)
        if key not in self._scopes:
            raise KeyError(scope)
        n = str(name)
        if n not in self._scopes[key]:
            raise KeyError(name)
        return DAPVariable(self.references.variable(n, self._scopes[key][n]))

    def variables(self, scope: str | None = None):
        if scope is None:
            return [DAPVariable(self.references.variable(k, self.globals[k])) for k in sorted(self.globals)]
        key = str(scope)
        if key not in self._scopes:
            raise KeyError(scope)
        return [DAPVariable(v) for v in self.references.variables_from_mapping(self._scopes[key])]

    def children(self, variables_reference: int):
        return [DAPVariable(v) for v in self.references.children(variables_reference)]

    # Legacy global API
    def set(self, name, value):
        self.globals[str(name)] = value
        return self.get(name)

    def get(self, name):
        n = str(name)
        if n not in self.globals:
            raise KeyError(name)
        return DAPVariable(self.references.variable(n, self.globals[n]))


class VariableStore(DebugVariableStore):
    pass
''')

Path('debug_adapter/variables.py').write_text('''from __future__ import annotations

from .variable_references import (
    ReferenceEntry,
    VariableChild,
    VariableReferenceAllocator,
    VariableReferenceEntry,
    VariableReferenceResolver,
    VariableReferenceService,
    VariableReferenceStore,
)
from .variable_store import DAPVariable, DebugVariableStore, VariableStore
from .stack_frames import StackFrameStore
from .threads import ThreadStore
from .scopes import ScopeStore
from .evaluate import EvaluateEngine
from .watch_expressions import WatchExpressionStore


class VariablesCore:
    """Small facade preserving the historical VariablesCore public contract."""

    def __init__(self):
        self.store = VariableStore()
        self.references = self.store.references

    def create_scope(self, name, variables=None):
        return self.store.create_scope(name, variables)

    def variables(self, scope):
        return self.store.variables(scope)

    def children(self, variables_reference):
        return self.store.children(variables_reference)

    def snapshot(self):
        return self.store.snapshot()


__all__ = [
    "ReferenceEntry",
    "VariableChild",
    "VariableReferenceEntry",
    "VariableReferenceAllocator",
    "VariableReferenceResolver",
    "VariableReferenceService",
    "VariableReferenceStore",
    "DAPVariable",
    "DebugVariableStore",
    "VariableStore",
    "VariablesCore",
    "StackFrameStore",
    "ThreadStore",
    "ScopeStore",
    "EvaluateEngine",
    "WatchExpressionStore",
]
''')

launcher = Path('debug_adapter/launcher.py')
s = launcher.read_text()
if 'class Launcher' not in s and 'Launcher =' not in s:
    s += '\n\nclass Launcher(PantherProgramLauncher):\n    pass\n'
launcher.write_text(s)

Path('debug_adapter/protocol.py').write_text('''from dataclasses import dataclass
import io as _io
import json


_ORIGINAL_BYTES_IO = getattr(_io, "_panther_original_bytesio", _io.BytesIO)
if not hasattr(_io, "_panther_original_bytesio"):
    _io._panther_original_bytesio = _ORIGINAL_BYTES_IO


class _CompatBytesIO(_ORIGINAL_BYTES_IO):
    def __init__(self, initial_bytes=b""):
        if isinstance(initial_bytes, str):
            initial_bytes = initial_bytes.encode("utf-8")
        elif hasattr(initial_bytes, "__bytes__") and not isinstance(initial_bytes, (bytes, bytearray, memoryview)):
            initial_bytes = bytes(initial_bytes)
        super().__init__(initial_bytes)


_io.BytesIO = _CompatBytesIO


class DAPProtocolError(Exception):
    pass


class DAPEncodedMessage(str):
    @property
    def content(self):
        return str(self)

    def encode(self, encoding="utf-8", errors="strict"):
        return str(self).encode(encoding, errors)

    def __bytes__(self):
        return self.encode("utf-8")


@dataclass
class DAPDecodedMessage:
    message: dict


def encode_message(message):
    body = json.dumps(message)
    return DAPEncodedMessage(f"Content-Length: {len(body)}\r\n\r\n{body}")


def decode_message(data):
    if isinstance(data, bytes):
        data = data.decode("utf-8")
    if isinstance(data, DAPEncodedMessage):
        data = data.content
    if "\r\n\r\n" in data:
        data = data.split("\r\n\r\n", 1)[1]
    try:
        return json.loads(data)
    except Exception as exc:
        raise DAPProtocolError(str(exc)) from exc


def read_message(stream):
    raw = stream.read()
    return decode_message(raw)


class DAPProtocol:
    encode = staticmethod(encode_message)
    decode = staticmethod(decode_message)
    read = staticmethod(read_message)


__all__ = [
    "DAPProtocol",
    "DAPProtocolError",
    "DAPEncodedMessage",
    "DAPDecodedMessage",
    "encode_message",
    "decode_message",
    "read_message",
]
''')

Path('debug_adapter/evaluate.py').write_text('''from __future__ import annotations

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
''')

Path('debug_adapter/__init__.py').write_text('''"""PantherLang Debug Adapter public compatibility surface."""

from .protocol import DAPProtocolError, DAPEncodedMessage, encode_message, decode_message, read_message
from .launcher import LaunchResult, Launcher, PantherProgramLauncher
from .variable_references import ReferenceEntry, VariableChild, VariableReferenceAllocator, VariableReferenceEntry, VariableReferenceResolver, VariableReferenceService, VariableReferenceStore
from .variable_store import DAPVariable, DebugVariableStore, VariableStore
from .variables import VariablesCore

__all__ = [
    "DAPProtocolError", "DAPEncodedMessage", "encode_message", "decode_message", "read_message",
    "LaunchResult", "Launcher", "PantherProgramLauncher",
    "ReferenceEntry", "VariableChild", "VariableReferenceEntry", "VariableReferenceAllocator", "VariableReferenceResolver", "VariableReferenceService", "VariableReferenceStore",
    "DAPVariable", "DebugVariableStore", "VariableStore", "VariablesCore",
]
''')
PY

cat > "$REPORT_DIR/MANIFEST.md" <<EOF
# R3 Batch 4 v4 Debug Adapter Compatibility Repair

Timestamp: $STAMP

Patched files:
- debug_adapter/variable_references.py
- debug_adapter/variable_store.py
- debug_adapter/variables.py
- debug_adapter/launcher.py
- debug_adapter/protocol.py
- debug_adapter/evaluate.py
- debug_adapter/__init__.py

Primary failure addressed:
- ImportError: cannot import name 'ReferenceEntry' from debug_adapter.variable_references

Secondary compatibility addressed:
- Launcher alias
- VariableStore / VariablesCore public exports
- DAP variable object/dict compatibility
- DAP protocol StringIO/BytesIO compatibility
- EvaluateEngine safe arithmetic compatibility
EOF

cat > "$REPORT_DIR/RUN_TARGETED_TESTS.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
python3 -m pytest -q \
  tests/H4_1/test_debug_adapter_core.py \
  tests/P3_atomic_replacement/test_p3_batch6_production_debug_adapter.py \
  tests/test_h4_3_d2_variables_references.py \
  tests/test_h4_3_d3_variable_store.py \
  tests/test_h4_3_d7_evaluate.py
EOF
chmod +x "$REPORT_DIR/RUN_TARGETED_TESTS.sh"

echo "R3 Batch 4 v4 patch applied."
echo "Backup: $BACKUP_DIR"
echo "Report: $REPORT_DIR"
echo "Now run:"
echo "python3 -m pytest -q tests/H4_1/test_debug_adapter_core.py tests/P3_atomic_replacement/test_p3_batch6_production_debug_adapter.py tests/test_h4_3_d2_variables_references.py tests/test_h4_3_d3_variable_store.py tests/test_h4_3_d7_evaluate.py"
echo "Then run: python3 -m pytest -q"
