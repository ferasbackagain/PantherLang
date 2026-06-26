#!/usr/bin/env bash
set -e

echo "🐾 PantherLang Phase 1.4 — Semantic Engine Bootstrap"
echo "Root: $(pwd)"

mkdir -p architecture/compiler language/compiler/core language/tests scripts

cat > architecture/compiler/SEMANTIC_ENGINE.md <<'EOF'
# Panther Semantic Engine

Responsibilities:
- Resolve symbols
- Validate types
- Detect duplicate declarations
- Validate model fields
- Prepare IR generation
EOF

cat > language/compiler/core/semantic_engine.py <<'EOF'
from compiler.core.diagnostics import DiagnosticBag
from compiler.core.type_checker import TypeChecker

class SemanticEngine:
    def __init__(self):
        self.types = TypeChecker()
        self.diagnostics = DiagnosticBag()

    def analyze_model(self, model):
        names = set()
        for field in model.fields:
            if field.name in names:
                self.diagnostics.error(f"Duplicate field: {field.name}")
            names.add(field.name)
        self.types.check_model(model, {model.name})
        return (not self.diagnostics.has_errors()
                and not self.types.diagnostics.has_errors())
EOF

cat > language/tests/test_phase1_semantic.py <<'EOF'
from language.models.core_models import PantherModel, PantherField
from language.compiler.core.semantic_engine import SemanticEngine

engine = SemanticEngine()

model = PantherModel(
    name="User",
    fields=[
        PantherField("id","uuid"),
        PantherField("name","string"),
        PantherField("email","string")
    ]
)

assert engine.analyze_model(model)
print("✅ Phase 1.4 semantic tests passed.")
EOF

cat > scripts/verify_phase1_semantic.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_semantic.py
echo "✅ PantherLang Phase 1.4 semantic verification complete."
EOF

chmod +x scripts/verify_phase1_semantic.sh

PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_semantic.py

echo "--------------------------------"
echo "✅ PantherLang Phase 1.4 Semantic Engine installed successfully."
echo "Run anytime: bash scripts/verify_phase1_semantic.sh"
echo "--------------------------------"
