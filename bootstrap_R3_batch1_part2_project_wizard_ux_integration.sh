#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Production Developer Experience"
echo " Batch 1 - Project System"
echo " Part 2 - Project Wizard UX Integration"
echo "============================================================"

ROOT="$(pwd)"
R3="$ROOT/.panther/R3_production_developer_experience"
REPORTS="$ROOT/reports/R3_project_system"
BACKUP="$ROOT/.panther/backups/R3_batch1_part2_project_wizard_ux_$(date +%Y%m%d_%H%M%S)"
EXT="$ROOT/vscode-extension"

mkdir -p "$R3" "$REPORTS" "$BACKUP"

fail(){ echo "[R3-B1-P2][ERROR] $1" >&2; exit 1; }

echo "[1/12] Pre-flight gates..."
[ -d ".git" ] || fail "Run from PantherLang project root."
[ -f "$R3/status_batch1_part1_project_wizard_foundation.json" ] || fail "Run R3 Batch 1 Part 1 first."
[ -d "$EXT" ] || fail "vscode-extension missing."
[ -f "$EXT/package.json" ] || fail "vscode-extension/package.json missing."
[ -f "tools/project_wizard/panther_new.py" ] || fail "Project wizard CLI missing."

echo "[2/12] Safety backup..."
cp -a "$EXT" "$BACKUP/vscode-extension"
cp -a tools/project_wizard "$BACKUP/project_wizard"
cp -a tests/R3_project_system "$BACKUP/tests_R3_project_system" 2>/dev/null || true

echo "[3/12] Baseline tests..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q
python3 -m pytest tests/R3_project_system/test_r3_batch1_part1_project_wizard.py -q

echo "[4/12] Adding project wizard metadata..."
mkdir -p tools/project_wizard

cat > tools/project_wizard/templates.json <<'EOF'
{
  "templates": [
    {
      "id": "console",
      "label": "Console App",
      "description": "A minimal PantherLang command-line application.",
      "folder": "console_app"
    },
    {
      "id": "web",
      "label": "Web App",
      "description": "A PantherLang web application starter.",
      "folder": "web_app"
    },
    {
      "id": "api",
      "label": "API App",
      "description": "A PantherLang REST/API service starter.",
      "folder": "api_app"
    },
    {
      "id": "ai",
      "label": "AI App",
      "description": "A PantherLang AI-ready application starter.",
      "folder": "ai_app"
    }
  ]
}
EOF

echo "[5/12] Enhancing wizard engine with metadata API..."
python3 <<'PY'
from pathlib import Path

p = Path("tools/project_wizard/wizard.py")
txt = p.read_text()

if "def template_metadata()" not in txt:
    txt += r