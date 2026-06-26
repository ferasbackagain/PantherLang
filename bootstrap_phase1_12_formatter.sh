#!/usr/bin/env bash
set -e

echo "🐾 PantherLang Phase 1.12 — Formatter Bootstrap"
echo "Root: $(pwd)"

mkdir -p language/tools/formatter language/tests scripts docs architecture/tools

cat > architecture/tools/FORMATTER.md <<'EOF'
# Panther Formatter — Phase 1.12

## Purpose
The Panther Formatter creates consistent formatting for `.panther` files.

## Phase 1.12 Scope
This first formatter handles:
- trimming trailing spaces
- normalizing blank lines
- ensuring final newline
- basic indentation around `{` and `}`

## Future Scope
- full AST-based formatting
- stable style guide
- Panther Studio integration
- CI formatting checks
EOF

cat > language/tools/formatter/panther_formatter.py <<'EOF'
class PantherFormatter:
    def format(self, source: str) -> str:
        lines = source.splitlines()
        output = []
        indent = 0

        for raw in lines:
            stripped = raw.strip()

            if not stripped:
                if output and output[-1] != "":
                    output.append("")
                continue

            if stripped.startswith("}"):
                indent = max(indent - 1, 0)

            output.append(("    " * indent) + stripped)

            if stripped.endswith("{"):
                indent += 1

        while output and output[-1] == "":
            output.pop()

        return "\n".join(output) + "\n"


def format_panther(source: str) -> str:
    return PantherFormatter().format(source)
EOF

cat > language/tools/formatter/__init__.py <<'EOF'
from .panther_formatter import PantherFormatter, format_panther
EOF

cat > language/tests/test_phase1_formatter.py <<'EOF'
from language.tools.formatter import format_panther

source = "app PantherStore {   \nmodel Product { \n id: uuid\n}\n}\n"
formatted = format_panther(source)

assert formatted.endswith("\n")
assert "app PantherStore {" in formatted
assert "    model Product {" in formatted
assert "        id: uuid" in formatted
assert formatted.count("\n\n\n") == 0

print("✅ Phase 1.12 formatter tests passed.")
EOF

cat > docs/FORMATTER.md <<'EOF'
# Panther Formatter

The formatter standardizes PantherLang source files.

## Current Rules
- Remove trailing whitespace.
- Normalize blank lines.
- Add a final newline.
- Indent nested blocks using four spaces.

## Command Future
```bash
panther fmt file.panther
```
EOF

cat > scripts/verify_phase1_formatter.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_formatter.py
echo "✅ PantherLang Phase 1.12 formatter verification complete."
EOF

chmod +x scripts/verify_phase1_formatter.sh

PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_formatter.py

echo "--------------------------------"
echo "✅ PantherLang Phase 1.12 Formatter installed successfully."
echo "Run anytime: bash scripts/verify_phase1_formatter.sh"
echo "--------------------------------"
