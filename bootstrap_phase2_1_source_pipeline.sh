#!/usr/bin/env bash
set -e

echo "🐾 PantherLang Phase 2.1 — Real Source Pipeline Bootstrap"
echo "Root: $(pwd)"

mkdir -p \
  architecture/phase2 \
  language/compiler/pipeline \
  language/examples \
  language/tests \
  scripts \
  docs

cat > architecture/phase2/PHASE_2_PLAN.md <<'EOF'
# PantherLang Phase 2 Plan

## Goal
Turn PantherLang from a foundation into a working source-file language pipeline.

## Phase 2 Modules

- 2.1 Real Source Pipeline
- 2.2 Real AST Builder
- 2.3 Model Parser
- 2.4 App Parser
- 2.5 API Parser
- 2.6 Page Parser
- 2.7 Agent Parser
- 2.8 Semantic Integration
- 2.9 IR Integration
- 2.10 End-to-End Compiler

## Phase 2 Success Definition

A `.panther` file can be read, tokenized, parsed, semantically checked, converted to IR, and compiled into generated target code.
EOF

cat > language/examples/phase2_panther_store.panther <<'EOF'
app PantherStore {
    version "0.5"
}

model Product {
    id: uuid
    title: string required
    price: decimal required
    stock: int = 0
}

model User {
    id: uuid
    name: string required
    email: string required
}

page Products {
    title "Products"
    table Product
}
EOF

cat > language/compiler/pipeline/source_pipeline.py <<'EOF'
from pathlib import Path
from language.compiler.core.lexer import tokenize
from language.compiler.core.parser import parse


class PantherSourcePipeline:
    def read_source(self, path):
        return Path(path).read_text()

    def tokenize_source(self, source):
        return tokenize(source)

    def parse_source(self, source):
        return parse(source)

    def run_file(self, path):
        source = self.read_source(path)
        tokens = self.tokenize_source(source)
        parsed = self.parse_source(source)
        return {
            "path": str(path),
            "source_length": len(source),
            "token_count": len(tokens),
            "parsed": parsed,
        }
EOF

cat > language/compiler/pipeline/__init__.py <<'EOF'
from .source_pipeline import PantherSourcePipeline
EOF

cat > language/tests/test_phase2_1_source_pipeline.py <<'EOF'
from language.compiler.pipeline import PantherSourcePipeline

pipeline = PantherSourcePipeline()
result = pipeline.run_file("language/examples/phase2_panther_store.panther")

assert result["source_length"] > 0
assert result["token_count"] > 10
assert result["parsed"]["node"] == "Program"
assert "PantherStore" in result["parsed"]["tokens"]
assert "Product" in result["parsed"]["tokens"]

print("✅ Phase 2.1 source pipeline tests passed.")
EOF

cat > docs/PHASE_2_STATUS.md <<'EOF'
# PantherLang Phase 2 Status

## Active Phase
Phase 2 — Real Source Pipeline

## Completed
- Phase 1 foundation
- Phase 2.1 source-file pipeline bootstrap

## Next
- 2.2 Real AST Builder
- 2.3 Model Parser
- 2.4 App Parser
- 2.5 API/Page/Agent parsing
- 2.10 End-to-End Compiler
EOF

cat > scripts/verify_phase2_1.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase2_1_source_pipeline.py
echo "✅ PantherLang Phase 2.1 source pipeline verification complete."
EOF

chmod +x scripts/verify_phase2_1.sh

PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase2_1_source_pipeline.py

echo "--------------------------------"
echo "✅ PantherLang Phase 2.1 Real Source Pipeline installed successfully."
echo "Run anytime: bash scripts/verify_phase2_1.sh"
echo "Next: Phase 2.2 Real AST Builder"
echo "--------------------------------"
