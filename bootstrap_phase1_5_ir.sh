#!/usr/bin/env bash
set -e

echo "🐾 PantherLang Phase 1.5 — IR Engine Bootstrap"
echo "Root: $(pwd)"

mkdir -p architecture/compiler language/compiler/core language/tests scripts

cat > architecture/compiler/IR_ENGINE.md <<'EOF'
# PantherLang IR Engine — Phase 1.5

## Purpose
IR means Intermediate Representation.

The IR is the stable internal format between:
- Parser
- Semantic Engine
- Type Checker
- Runtime
- Future Code Generator

## Pipeline
Source → Lexer → Tokens → Parser → AST → Semantic Engine → IR → Runtime/Codegen

## Phase 1.5 Scope
This phase introduces the first official Panther IR model:
- IRProgram
- IRModel
- IRField
- IRBuilder

## Design Rules
1. IR must be simple.
2. IR must be serializable.
3. IR must be independent from Python implementation details.
4. IR must support future targets: native, WASM, web, cloud, AI runtime.
EOF

cat > language/compiler/core/ir_nodes.py <<'EOF'
from dataclasses import dataclass, field
from typing import Any, Dict, List


@dataclass
class IRField:
    name: str
    type_name: str
    required: bool = False
    nullable: bool = False
    default: Any = None

    def to_dict(self):
        return {
            "kind": "IRField",
            "name": self.name,
            "type": self.type_name,
            "required": self.required,
            "nullable": self.nullable,
            "default": self.default,
        }


@dataclass
class IRModel:
    name: str
    fields: List[IRField] = field(default_factory=list)

    def to_dict(self):
        return {
            "kind": "IRModel",
            "name": self.name,
            "fields": [field.to_dict() for field in self.fields],
        }


@dataclass
class IRProgram:
    name: str = "PantherProgram"
    models: List[IRModel] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self):
        return {
            "kind": "IRProgram",
            "name": self.name,
            "models": [model.to_dict() for model in self.models],
            "metadata": self.metadata,
        }
EOF

cat > language/compiler/core/ir_builder.py <<'EOF'
from compiler.core.ir_nodes import IRProgram, IRModel, IRField


class IRBuilder:
    def build_model(self, model):
        fields = [
            IRField(
                name=field.name,
                type_name=field.type_name,
                required=field.required,
                nullable=field.nullable,
                default=field.default,
            )
            for field in model.fields
        ]
        return IRModel(name=model.name, fields=fields)

    def build_program_from_models(self, models, name="PantherProgram"):
        program = IRProgram(name=name)
        for model in models:
            program.models.append(self.build_model(model))
        return program
EOF

cat > language/compiler/core/ir_serializer.py <<'EOF'
import json


def ir_to_json(ir_program, indent=2):
    return json.dumps(ir_program.to_dict(), indent=indent)
EOF

cat > language/tests/test_phase1_ir.py <<'EOF'
from language.models.core_models import PantherModel, PantherField
from language.compiler.core.ir_builder import IRBuilder
from language.compiler.core.ir_serializer import ir_to_json


product = PantherModel(
    name="Product",
    fields=[
        PantherField("id", "uuid"),
        PantherField("title", "string", required=True),
        PantherField("price", "decimal", required=True),
    ],
)

builder = IRBuilder()
ir = builder.build_program_from_models([product], name="PantherStore")
data = ir.to_dict()

assert data["kind"] == "IRProgram"
assert data["name"] == "PantherStore"
assert data["models"][0]["name"] == "Product"
assert data["models"][0]["fields"][1]["required"] is True

json_output = ir_to_json(ir)
assert "PantherStore" in json_output
assert "Product" in json_output

print("✅ Phase 1.5 IR tests passed.")
EOF

cat > scripts/verify_phase1_ir.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_ir.py
echo "✅ PantherLang Phase 1.5 IR verification complete."
EOF

chmod +x scripts/verify_phase1_ir.sh

PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_ir.py

echo "--------------------------------"
echo "✅ PantherLang Phase 1.5 IR Engine installed successfully."
echo "Run anytime: bash scripts/verify_phase1_ir.sh"
echo "--------------------------------"
