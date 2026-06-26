#!/usr/bin/env bash
set -e

echo "🐾 PantherLang Phase 1.13 — Documentation Generator Bootstrap"
echo "Root: $(pwd)"

mkdir -p language/tools/docsgen language/tests scripts docs/generated architecture/tools

cat > architecture/tools/DOCUMENTATION_GENERATOR.md <<'EOF'
# Panther Documentation Generator — Phase 1.13

## Purpose
The documentation generator creates project documentation from Panther specifications, examples, and source metadata.

## Phase 1.13 Scope
- Generate Markdown documentation.
- Read official specification files.
- Produce generated summary docs.
- Prepare for future Panther Studio and Panther Academy integration.

## Future Scope
- API reference generation.
- AST-based documentation extraction.
- HTML documentation output.
- Search index generation.
- AI-readable knowledge base export.
EOF

cat > language/tools/docsgen/docgen.py <<'EOF'
from pathlib import Path


class PantherDocGenerator:
    def __init__(self, root="."):
        self.root = Path(root)

    def read_if_exists(self, path):
        p = self.root / path
        if p.exists():
            return p.read_text()
        return ""

    def generate_summary(self):
        spec = self.read_if_exists("architecture/specification/PANTHER_LANGUAGE_SPECIFICATION_v1_8.md")
        stdlib = self.read_if_exists("docs/STANDARD_LIBRARY.md")
        cli = self.read_if_exists("docs/CLI.md")
        formatter = self.read_if_exists("docs/FORMATTER.md")

        sections = [
            "# PantherLang Generated Documentation",
            "",
            "## Source Documents",
            "- Language Specification",
            "- Standard Library",
            "- CLI",
            "- Formatter",
            "",
            "## Language Specification Snapshot",
            self._first_lines(spec, 30),
            "",
            "## Standard Library Snapshot",
            self._first_lines(stdlib, 20),
            "",
            "## CLI Snapshot",
            self._first_lines(cli, 20),
            "",
            "## Formatter Snapshot",
            self._first_lines(formatter, 20),
            "",
        ]

        return "\\n".join(sections)

    def _first_lines(self, text, count):
        lines = text.splitlines()
        return "\\n".join(lines[:count]) if lines else "_Not available yet._"

    def write_generated_docs(self):
        output_dir = self.root / "docs" / "generated"
        output_dir.mkdir(parents=True, exist_ok=True)
        output_file = output_dir / "PANTHERLANG_GENERATED_DOCS.md"
        output_file.write_text(self.generate_summary() + "\\n")
        return output_file
EOF

cat > language/tools/docsgen/__init__.py <<'EOF'
from .docgen import PantherDocGenerator
EOF

cat > language/tests/test_phase1_docsgen.py <<'EOF'
from pathlib import Path
from language.tools.docsgen import PantherDocGenerator

gen = PantherDocGenerator(".")
output = gen.write_generated_docs()

assert output.exists()
text = output.read_text()
assert "PantherLang Generated Documentation" in text
assert "Language Specification" in text

print("✅ Phase 1.13 documentation generator tests passed.")
EOF

cat > docs/DOCUMENTATION_GENERATOR.md <<'EOF'
# Panther Documentation Generator

The Panther documentation generator creates generated project documentation from official specifications and source metadata.

## Current Output
```text
docs/generated/PANTHERLANG_GENERATED_DOCS.md
```

## Future Command
```bash
panther docs
```
EOF

cat > scripts/verify_phase1_docsgen.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_docsgen.py
test -f docs/generated/PANTHERLANG_GENERATED_DOCS.md
echo "✅ PantherLang Phase 1.13 documentation generator verification complete."
EOF

chmod +x scripts/verify_phase1_docsgen.sh

PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_docsgen.py

echo "--------------------------------"
echo "✅ PantherLang Phase 1.13 Documentation Generator installed successfully."
echo "Run anytime: bash scripts/verify_phase1_docsgen.sh"
echo "Generated docs: docs/generated/PANTHERLANG_GENERATED_DOCS.md"
echo "--------------------------------"
