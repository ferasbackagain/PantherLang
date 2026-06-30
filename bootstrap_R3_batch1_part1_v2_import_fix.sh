#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Batch 1 Part 1 v2 - Project Wizard Import Fix"
echo "============================================================"

ROOT="$(pwd)"
R3="$ROOT/.panther/R3_production_developer_experience"
REPORTS="$ROOT/reports/R3_project_system"
BACKUP="$ROOT/.panther/backups/R3_batch1_part1_v2_import_fix_$(date +%Y%m%d_%H%M%S)"
EXT="$ROOT/vscode-extension"

mkdir -p "$R3" "$REPORTS" "$BACKUP"

fail(){ echo "[R3-B1-P1-v2][ERROR] $1" >&2; exit 1; }

echo "[1/8] Pre-flight..."
[ -d ".git" ] || fail "Run from PantherLang project root."
[ -f "tools/project_wizard/panther_new.py" ] || fail "panther_new.py missing."
[ -f "tools/project_wizard/wizard.py" ] || fail "wizard.py missing."

echo "[2/8] Safety backup..."
cp -a tools/project_wizard "$BACKUP/project_wizard"
cp -a tests/R3_project_system "$BACKUP/tests_R3_project_system" 2>/dev/null || true
cp -a "$EXT" "$BACKUP/vscode-extension" 2>/dev/null || true

echo "[3/8] Fixing CLI import path..."
cat > tools/project_wizard/panther_new.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Allow running as:
#   python3 tools/project_wizard/panther_new.py
# without requiring PYTHONPATH to be set.
PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from tools.project_wizard.wizard import available_templates, create_project


def main() -> int:
    parser = argparse.ArgumentParser(description="Create a new PantherLang project.")
    parser.add_argument("name", help="Project name")
    parser.add_argument("--template", default="console", choices=available_templates())
    parser.add_argument("--destination", default=".")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = create_project(args.name, args.template, Path(args.destination))
    if args.json:
        print(json.dumps({
            "ok": True,
            "name": result.name,
            "template": result.template,
            "destination": str(result.destination),
            "files_created": result.files_created,
        }, indent=2))
    else:
        print(f"✅ Created PantherLang {result.template} project: {result.destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x tools/project_wizard/panther_new.py

echo "[4/8] Static validation..."
python3 -m py_compile tools/project_wizard/__init__.py tools/project_wizard/wizard.py tools/project_wizard/panther_new.py

echo "[5/8] Running R3 project wizard tests..."
python3 -m pytest tests/R3_project_system/test_r3_batch1_part1_project_wizard.py -q

echo "[6/8] Rebuilding VSIX 1.0.1..."
python3 <<'PY'
from pathlib import Path
import json
pkg_path = Path("vscode-extension/package.json")
pkg = json.loads(pkg_path.read_text())
pkg["version"] = "1.0.1"
pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
PY

(
  cd vscode-extension
  rm -f pantherlang-1.0.1*.vsix
  npx --yes @vscode/vsce package --no-dependencies
)

mkdir -p releases/vscode_marketplace
VSIX="$(ls -t vscode-extension/pantherlang-1.0.1*.vsix | head -1)"
[ -f "$VSIX" ] || fail "VSIX 1.0.1 not created."
cp "$VSIX" releases/vscode_marketplace/
sha256sum "releases/vscode_marketplace/$(basename "$VSIX")" > "releases/vscode_marketplace/$(basename "$VSIX").sha256"

echo "[7/8] Writing manifest/report..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
r3 = root / ".panther/R3_production_developer_experience"
vsix = root / "releases/vscode_marketplace" / "$(basename "$VSIX")"

manifest = {
    "ok": True,
    "phase": "R3",
    "batch": "1",
    "part": "1-v2",
    "name": "Project Wizard Import Fix",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "1.0.1",
    "fixed": "panther_new.py now injects project root into sys.path when executed directly",
    "tests": "tests/R3_project_system/test_r3_batch1_part1_project_wizard.py",
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "next": "R3 Batch 1 Part 2 - Project Wizard UX Integration"
}
(r3 / "batch1_part1_v2_import_fix_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ manifest written")
PY

cat > "$REPORTS/R3_BATCH1_PART1_V2_PROJECT_WIZARD_IMPORT_FIX.md" <<EOF
# R3 Batch 1 Part 1 v2 - Project Wizard Import Fix

## Status

PASSED

## Fixed

\`tools/project_wizard/panther_new.py\` can now run directly without \`ModuleNotFoundError: No module named 'tools'\`.

## Tests

\`\`\`bash
python3 -m pytest tests/R3_project_system/test_r3_batch1_part1_project_wizard.py -q
\`\`\`

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Next

R3 Batch 1 Part 2 - Project Wizard UX Integration.
EOF

echo "[8/8] Writing status..."
cat > "$R3/status_batch1_part1_project_wizard_foundation.json" <<EOF
{
  "ok": true,
  "phase": "R3",
  "batch": "1",
  "part": "1",
  "status": "PASSED",
  "name": "Project Wizard Foundation",
  "version": "1.0.1",
  "runtime_modified": true,
  "vsix": "releases/vscode_marketplace/$(basename "$VSIX")",
  "next": "R3 Batch 1 Part 2 - Project Wizard UX Integration"
}
EOF

echo "============================================================"
echo "✅ R3 Batch 1 Part 1 COMPLETE"
echo "✅ Import fix passed"
echo "VSIX: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Next: R3 Batch 1 Part 2 - Project Wizard UX Integration"
echo "============================================================"
