#!/usr/bin/env bash
set -e
echo "🐾 PantherLang Phase 1.7 — First Compiler Bootstrap"
echo "Root: $(pwd)"

mkdir -p architecture/compiler language/compiler/core language/tests scripts

cat > architecture/compiler/FIRST_COMPILER.md <<'EOF'
# PantherLang Phase 1.7
First executable compiler pipeline.

Source
 -> Lexer
 -> Parser
 -> Semantic
 -> IR
 -> Code Generator
EOF

cat > language/compiler/core/compiler.py <<'EOF'
from language.compiler.core.ir_builder import IRBuilder
from language.compiler.core.codegen import PythonCodeGenerator

class PantherCompiler:
    def compile_models(self, models, app_name="PantherApp"):
        ir = IRBuilder().build_program_from_models(models, name=app_name)
        return PythonCodeGenerator().generate(ir)
EOF

cat > language/tests/test_phase1_compiler.py <<'EOF'
from language.models.core_models import PantherModel, PantherField
from language.compiler.core.compiler import PantherCompiler

m = PantherModel(
    name="User",
    fields=[
        PantherField("id","uuid"),
        PantherField("name","string",required=True),
    ],
)

code = PantherCompiler().compile_models([m],"PantherDemo")
assert "PantherDemo" in code
assert "User" in code
print("✅ Phase 1.7 compiler tests passed.")
EOF

cat > scripts/verify_phase1_compiler.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_compiler.py
echo "✅ PantherLang Phase 1.7 compiler verification complete."
EOF

chmod +x scripts/verify_phase1_compiler.sh
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_compiler.py
echo "--------------------------------"
echo "✅ PantherLang Phase 1.7 First Compiler installed successfully."
echo "Run anytime: bash scripts/verify_phase1_compiler.sh"
echo "--------------------------------"
