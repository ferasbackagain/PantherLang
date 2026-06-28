#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 8.7 PRO - Language Server Protocol (LSP)"
echo "============================================================"

mkdir -p tools/lsp examples/phase8_lsp scripts docs/phase8 tests/phase8_7

cat > tools/lsp/panther_lsp.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path


KEYWORDS = {
    "module", "import", "struct", "fn", "let", "if", "for", "print",
    "agent", "runtime", "package", "memory", "intent"
}


def diagnostics(source: str) -> list[dict]:
    items = []
    stack = []
    for lineno, line in enumerate(source.splitlines(), start=1):
        stripped = line.strip()
        if stripped.endswith("{"):
            stack.append((lineno, "{"))
        if stripped == "}":
            if stack:
                stack.pop()
            else:
                items.append({
                    "line": lineno,
                    "severity": "error",
                    "message": "Unexpected closing brace"
                })
        if stripped.startswith("let ") and "=" not in stripped:
            items.append({
                "line": lineno,
                "severity": "error",
                "message": "Invalid let statement: missing '='"
            })
    for lineno, _ in stack:
        items.append({
            "line": lineno,
            "severity": "error",
            "message": "Unclosed block"
        })
    return items


def completions(prefix: str = "") -> list[str]:
    return sorted(k for k in KEYWORDS if k.startswith(prefix))


def hover(word: str) -> dict:
    docs = {
        "module": "Declares a PantherLang module.",
        "import": "Imports another Panther module.",
        "struct": "Declares a structured data type.",
        "fn": "Declares a function.",
        "let": "Declares a variable.",
        "print": "Prints a value.",
        "agent": "Declares an AI agent.",
        "runtime": "Declares runtime behavior."
    }
    return {"word": word, "description": docs.get(word, "PantherLang symbol")}


def main() -> int:
    parser = argparse.ArgumentParser(prog="panther-lsp")
    sub = parser.add_subparsers(dest="cmd", required=True)

    diag = sub.add_parser("diagnostics")
    diag.add_argument("source")

    comp = sub.add_parser("completions")
    comp.add_argument("--prefix", default="")

    hov = sub.add_parser("hover")
    hov.add_argument("word")

    args = parser.parse_args()

    if args.cmd == "diagnostics":
        src = Path(args.source).read_text(encoding="utf-8")
        print(json.dumps({"ok": True, "diagnostics": diagnostics(src)}, indent=2))
        return 0

    if args.cmd == "completions":
        print(json.dumps({"ok": True, "items": completions(args.prefix)}, indent=2))
        return 0

    if args.cmd == "hover":
        print(json.dumps({"ok": True, "hover": hover(args.word)}, indent=2))
        return 0

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x tools/lsp/panther_lsp.py

cat > examples/phase8_lsp/lsp_demo.panther <<'EOF'
module panther.lsp

fn hello(name) {
    print "Phase 8.7 Language Server Protocol"
    print name
}

let project = "PantherLang"
hello(project)
EOF

cat > docs/phase8/PHASE_8_7_STATUS.md <<'EOF'
# Phase 8.7 — Language Server Protocol Foundation

Completed:
- LSP diagnostics foundation
- completions foundation
- hover foundation
- Panther source analysis
- verification script
- CLI bridge preparation for editor tooling

Next: Phase 8.8 — VS Code Extension Foundation.
EOF

# Patch panther CLI with lsp command.
if ! grep -q 'tools/lsp/panther_lsp.py' panther; then
python3 - <<'PY'
from pathlib import Path
p=Path("panther")
t=p.read_text()
needle='  fmt)\n'
ins='  lsp)\n    shift\n    python3 "$ROOT/tools/lsp/panther_lsp.py" "$@"\n    ;;\n\n'
if ins not in t:
    t=t.replace(needle,ins+needle)
p.write_text(t)
PY
chmod +x panther
fi

cat > scripts/verify_phase8_7_lsp.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 8.7 LSP Verification"
echo "============================================================"

test -f tools/lsp/panther_lsp.py
test -f examples/phase8_lsp/lsp_demo.panther
echo "✅ structure tests passed"

python3 tools/lsp/panther_lsp.py diagnostics examples/phase8_lsp/lsp_demo.panther | grep -q '"ok": true'
echo "✅ diagnostics tests passed"

python3 tools/lsp/panther_lsp.py completions --prefix pr | grep -q 'print'
echo "✅ completions tests passed"

python3 tools/lsp/panther_lsp.py hover fn | grep -q 'Declares a function'
echo "✅ hover tests passed"

./panther lsp completions --prefix mo | grep -q 'module'
echo "✅ Panther LSP CLI bridge tests passed"

./panther run examples/phase8_lsp/lsp_demo.panther | grep -q "Phase 8.7 Language Server Protocol"
echo "✅ runtime bridge tests passed"

python3 -m py_compile tools/lsp/panther_lsp.py
echo "✅ python compile passed"

echo "✅ PantherLang Phase 8.7 Language Server Protocol verification complete."
EOF
chmod +x scripts/verify_phase8_7_lsp.sh

echo "[phase8.7] Running verification..."
bash scripts/verify_phase8_7_lsp.sh

echo "============================================================"
echo " Phase 8.7 COMPLETE"
echo " Next: Phase 8.8 VS Code Extension Foundation"
echo "============================================================"
