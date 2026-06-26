#!/usr/bin/env bash
set -e

echo "🐾 PantherLang Phase 1.9 — Standard Library Bootstrap"
echo "Root: $(pwd)"

mkdir -p \
  architecture/stdlib \
  language/stdlib/core \
  language/stdlib/math \
  language/stdlib/string \
  language/stdlib/collections \
  language/stdlib/datetime \
  language/stdlib/json \
  language/stdlib/http \
  language/stdlib/security \
  language/stdlib/ai \
  language/tests \
  scripts \
  docs

cat > architecture/stdlib/PANTHER_STANDARD_LIBRARY.md <<'EOF'
# Panther Standard Library — Phase 1.9

## Purpose
The Panther Standard Library (PSL) provides official built-in modules for PantherLang.

## Official Packages
- panther.core
- panther.math
- panther.string
- panther.collections
- panther.datetime
- panther.json
- panther.http
- panther.security
- panther.ai

## Design Rules
1. Standard library modules must be small and predictable.
2. Every module must be AI-readable.
3. Dangerous capabilities must require explicit permission.
4. Standard modules must support future Panther Runtime and Panther Studio.
EOF

cat > language/stdlib/core/__init__.py <<'EOF'
def identity(value):
    return value

def is_null(value):
    return value is None

def type_of(value):
    return type(value).__name__
EOF

cat > language/stdlib/math/__init__.py <<'EOF'
def add(a, b):
    return a + b

def subtract(a, b):
    return a - b

def multiply(a, b):
    return a * b

def divide(a, b):
    if b == 0:
        raise ValueError("division by zero")
    return a / b
EOF

cat > language/stdlib/string/__init__.py <<'EOF'
def upper(value):
    return str(value).upper()

def lower(value):
    return str(value).lower()

def trim(value):
    return str(value).strip()

def contains(value, part):
    return str(part) in str(value)
EOF

cat > language/stdlib/collections/__init__.py <<'EOF'
def count(items):
    return len(items)

def first(items):
    return items[0] if items else None

def last(items):
    return items[-1] if items else None

def unique(items):
    return list(dict.fromkeys(items))
EOF

cat > language/stdlib/datetime/__init__.py <<'EOF'
from datetime import datetime, timezone

def now():
    return datetime.now(timezone.utc).isoformat()

def today():
    return datetime.now(timezone.utc).date().isoformat()
EOF

cat > language/stdlib/json/__init__.py <<'EOF'
import json as _json

def parse(text):
    return _json.loads(text)

def stringify(value):
    return _json.dumps(value, indent=2)
EOF

cat > language/stdlib/http/__init__.py <<'EOF'
class HttpResponse:
    def __init__(self, status=200, body=None):
        self.status = status
        self.body = body or {}

    def to_dict(self):
        return {"status": self.status, "body": self.body}

def ok(body=None):
    return HttpResponse(200, body).to_dict()

def created(body=None):
    return HttpResponse(201, body).to_dict()

def error(message, status=400):
    return HttpResponse(status, {"error": message}).to_dict()
EOF

cat > language/stdlib/security/__init__.py <<'EOF'
def deny_by_default():
    return True

def require_capability(name, allowed):
    if name not in allowed:
        raise PermissionError(f"Capability denied: {name}")
    return True
EOF

cat > language/stdlib/ai/__init__.py <<'EOF'
class AgentSpec:
    def __init__(self, name, purpose="", tools=None, memory="none"):
        self.name = name
        self.purpose = purpose
        self.tools = tools or []
        self.memory = memory

    def to_dict(self):
        return {
            "name": self.name,
            "purpose": self.purpose,
            "tools": self.tools,
            "memory": self.memory,
        }
EOF

cat > language/stdlib/__init__.py <<'EOF'
# Panther Standard Library
EOF

cat > language/tests/test_phase1_stdlib.py <<'EOF'
from language.stdlib.core import identity, type_of
from language.stdlib.math import add, divide
from language.stdlib.string import upper, trim
from language.stdlib.collections import count, first, unique
from language.stdlib.json import parse, stringify
from language.stdlib.http import ok
from language.stdlib.security import deny_by_default
from language.stdlib.ai import AgentSpec

assert identity("Panther") == "Panther"
assert type_of(123) == "int"
assert add(2, 3) == 5
assert divide(10, 2) == 5
assert upper("panther") == "PANTHER"
assert trim("  ai  ") == "ai"
assert count([1, 2, 3]) == 3
assert first(["a", "b"]) == "a"
assert unique([1, 1, 2]) == [1, 2]
assert parse('{"x":1}')["x"] == 1
assert "x" in stringify({"x": 1})
assert ok({"ready": True})["status"] == 200
assert deny_by_default() is True
assert AgentSpec("Assistant", "Help users", ["data"], "scoped").to_dict()["memory"] == "scoped"

print("✅ Phase 1.9 standard library tests passed.")
EOF

cat > docs/STANDARD_LIBRARY.md <<'EOF'
# Panther Standard Library

## Phase 1.9 Modules

- panther.core
- panther.math
- panther.string
- panther.collections
- panther.datetime
- panther.json
- panther.http
- panther.security
- panther.ai

This is the foundation of PantherLang's official standard library.
EOF

cat > scripts/verify_phase1_stdlib.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_stdlib.py
echo "✅ PantherLang Phase 1.9 standard library verification complete."
EOF

chmod +x scripts/verify_phase1_stdlib.sh

PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_stdlib.py

echo "--------------------------------"
echo "✅ PantherLang Phase 1.9 Standard Library installed successfully."
echo "Run anytime: bash scripts/verify_phase1_stdlib.sh"
echo "--------------------------------"
