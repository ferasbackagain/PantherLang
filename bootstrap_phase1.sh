#!/usr/bin/env bash
set -e

echo "🐾 PantherLang Phase 1 Bootstrap"
echo "Root: $(pwd)"

mkdir -p architecture/specification architecture/compiler language/models language/compiler/core language/tests docs scripts

cat > architecture/specification/PANTHER_LANGUAGE_SPECIFICATION.md <<'EOF'
# PantherLang Language Specification — Phase 1

## Identity
PantherLang is an independent AI-native programming language.

## Mission
Build complete systems from one source of truth.

## Official Extension
.panther

## Official Command
panther

## Core Principles
1. AI-first.
2. Human-readable.
3. Strongly typed.
4. Secure by default.
5. Low boilerplate.
6. Semantic before syntax.
7. One source of truth.
8. Future self-hosting.

## Official Keywords
app, module, package, import, from, as, let, var, const, fn, return, if, else, match, case, for, while, break, continue, try, catch, throw, error, result, model, entity, struct, enum, interface, data, api, page, ui, workflow, agent, task, event, service, async, await, capabilities, allow, deny, security, policy, permission, secret, deploy, target, runtime, true, false, null, void

## Official Types
int, float, decimal, bool, string, char, bytes, uuid, date, time, datetime, duration, json, any, void

## Collection Types
list<T>, array<T>, map<K,V>, set<T>, tuple<T...>

## Advanced Types
optional<T>, result<T,E>, future<T>, stream<T>

## Nullable
User?
Product?
EOF

cat > architecture/specification/MODELS_SPEC.md <<'EOF'
# PantherLang Models Specification

Models are semantic entities understood by the compiler, runtime, API engine, UI engine, and AI systems.

## Example

```panther
model Product {
    id: uuid
    title: string required
    price: decimal required
    stock: int = 0
}
```

## Rules
1. Model names use PascalCase.
2. Field names use snake_case.
3. Field types must be known Panther types or user-defined models.
4. Values are non-null by default.
5. Nullable fields use `?`.
6. Money and prices use `decimal`, not float.
EOF

cat > architecture/compiler/TYPE_SYSTEM.md <<'EOF'
# Panther Type System — Phase 1

## Goal
The Panther type system makes code safe, clear, AI-readable, and scalable.

## Primitive Types
int, float, decimal, bool, string, char, bytes, uuid, date, time, datetime, duration, json, any, void

## Collections
list<T>, array<T>, map<K,V>, set<T>, tuple<T...>

## Advanced
optional<T>, result<T,E>, future<T>, stream<T>

## Rules
1. Non-null by default.
2. Nullable must be explicit.
3. Required fields must be validated.
4. Prices use decimal.
5. Dangerous implicit casts are forbidden.
EOF

cat > language/models/core_models.py <<'EOF'
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

@dataclass
class PantherField:
    name: str
    type_name: str
    required: bool = False
    nullable: bool = False
    default: Optional[Any] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class PantherModel:
    name: str
    fields: List[PantherField] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def field_names(self) -> List[str]:
        return [field.name for field in self.fields]

@dataclass
class PantherAPI:
    method: str
    path: str
    model: Optional[str] = None
    action: Optional[str] = None
    public: bool = False
    secure_role: Optional[str] = None

@dataclass
class PantherPage:
    name: str
    title: str = ""
    tables: List[str] = field(default_factory=list)
    forms: List[str] = field(default_factory=list)

@dataclass
class PantherAgent:
    name: str
    purpose: str = ""
    tools: List[str] = field(default_factory=list)
    memory: str = "none"

@dataclass
class PantherApplication:
    name: str
    version: str = "0.1"
    models: List[PantherModel] = field(default_factory=list)
    apis: List[PantherAPI] = field(default_factory=list)
    pages: List[PantherPage] = field(default_factory=list)
    agents: List[PantherAgent] = field(default_factory=list)
EOF

cat > language/models/__init__.py <<'EOF'
from .core_models import PantherField, PantherModel, PantherAPI, PantherPage, PantherAgent, PantherApplication
EOF

cat > language/compiler/core/semantic_types.py <<'EOF'
from dataclasses import dataclass

@dataclass(frozen=True)
class PantherType:
    name: str
    nullable: bool = False
    generic_args: tuple = ()

    def __str__(self):
        base = self.name
        if self.generic_args:
            base += "<" + ", ".join(str(arg) for arg in self.generic_args) + ">"
        if self.nullable:
            base += "?"
        return base

PRIMITIVE_TYPES = {"int","float","decimal","bool","string","char","bytes","uuid","date","time","datetime","duration","json","any","void"}
COLLECTION_TYPES = {"list","array","map","set","tuple"}
ADVANCED_TYPES = {"optional","result","future","stream"}
ALL_BUILTIN_TYPES = PRIMITIVE_TYPES | COLLECTION_TYPES | ADVANCED_TYPES

def is_builtin_type(type_name: str) -> bool:
    return type_name in ALL_BUILTIN_TYPES

def parse_type(type_name: str) -> PantherType:
    nullable = type_name.endswith("?")
    clean = type_name[:-1] if nullable else type_name
    return PantherType(name=clean, nullable=nullable)
EOF

cat > language/compiler/core/diagnostics.py <<'EOF'
from dataclasses import dataclass
from typing import List

@dataclass
class Diagnostic:
    level: str
    message: str
    line: int = 0
    column: int = 0

    def format(self) -> str:
        location = f"{self.line}:{self.column}" if self.line else "unknown"
        return f"[{self.level.upper()}] {location} - {self.message}"

class DiagnosticBag:
    def __init__(self):
        self.items: List[Diagnostic] = []

    def error(self, message: str, line: int = 0, column: int = 0):
        self.items.append(Diagnostic("error", message, line, column))

    def warning(self, message: str, line: int = 0, column: int = 0):
        self.items.append(Diagnostic("warning", message, line, column))

    def has_errors(self) -> bool:
        return any(item.level == "error" for item in self.items)

    def print_all(self):
        for item in self.items:
            print(item.format())
EOF

cat > language/compiler/core/symbol_table.py <<'EOF'
from dataclasses import dataclass, field
from typing import Dict, Optional

@dataclass
class Symbol:
    name: str
    kind: str
    type_name: str = ""
    metadata: dict = field(default_factory=dict)

class SymbolTable:
    def __init__(self):
        self.symbols: Dict[str, Symbol] = {}

    def define(self, symbol: Symbol) -> bool:
        if symbol.name in self.symbols:
            return False
        self.symbols[symbol.name] = symbol
        return True

    def resolve(self, name: str) -> Optional[Symbol]:
        return self.symbols.get(name)

    def all_symbols(self):
        return list(self.symbols.values())
EOF

cat > language/compiler/core/scope.py <<'EOF'
from typing import Optional
from compiler.core.symbol_table import Symbol, SymbolTable

class Scope:
    def __init__(self, parent: Optional["Scope"] = None):
        self.parent = parent
        self.table = SymbolTable()

    def define(self, symbol: Symbol) -> bool:
        return self.table.define(symbol)

    def resolve(self, name: str):
        found = self.table.resolve(name)
        if found:
            return found
        if self.parent:
            return self.parent.resolve(name)
        return None
EOF

cat > language/compiler/core/type_checker.py <<'EOF'
from compiler.core.semantic_types import is_builtin_type
from compiler.core.diagnostics import DiagnosticBag

class TypeChecker:
    def __init__(self):
        self.diagnostics = DiagnosticBag()

    def check_field_type(self, type_name: str, known_models=None):
        known_models = known_models or set()
        clean = type_name[:-1] if type_name.endswith("?") else type_name
        if clean in known_models or is_builtin_type(clean):
            return True
        self.diagnostics.error(f"Unknown type: {type_name}")
        return False

    def check_model(self, model, known_models=None):
        known_models = known_models or {model.name}
        for field in model.fields:
            self.check_field_type(field.type_name, known_models)
        return not self.diagnostics.has_errors()
EOF

cat > language/tests/test_phase1_models.py <<'EOF'
from language.models.core_models import PantherField, PantherModel
from language.compiler.core.type_checker import TypeChecker
from language.compiler.core.semantic_types import parse_type

product = PantherModel(
    name="Product",
    fields=[
        PantherField("id", "uuid"),
        PantherField("title", "string", required=True),
        PantherField("price", "decimal", required=True),
        PantherField("stock", "int", default=0),
    ],
)

checker = TypeChecker()
assert checker.check_model(product)
assert product.field_names() == ["id", "title", "price", "stock"]

nullable_user = parse_type("User?")
assert nullable_user.name == "User"
assert nullable_user.nullable is True

print("✅ Phase 1 bootstrap tests passed.")
EOF

cat > docs/PHASE_1_STATUS.md <<'EOF'
# PantherLang Phase 1 Status

## Active Phase
Phase 1 — PantherLang Core

## Completed by bootstrap_phase1.sh
- Language Specification
- Models Specification
- Type System Specification
- Core Models
- Semantic Type System
- Diagnostics
- Symbol Table
- Scope
- Type Checker Foundation
- Phase 1 Tests

## Next
- Official colors and visual identity
- Lexer 2.0
- Parser 2.0
- AST 2.0
- Semantic Engine integration
EOF

cat > scripts/verify_phase1.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_models.py
echo "✅ PantherLang Phase 1 verification complete."
EOF

chmod +x scripts/verify_phase1.sh
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_models.py

echo "--------------------------------"
echo "✅ PantherLang Phase 1 bootstrap installed successfully."
echo "Run anytime: bash scripts/verify_phase1.sh"
echo "--------------------------------"
