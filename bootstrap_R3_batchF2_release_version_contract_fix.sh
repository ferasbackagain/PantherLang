#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP="$ROOT/.panther/backups/R3_batchF2_release_version_contract_$STAMP"
REPORT="$ROOT/.panther/reports/R3_batchF2_release_version_contract_$STAMP"

mkdir -p "$BACKUP" "$REPORT"

echo "== R3 Batch F2: Release Version Contract Fix =="

TEST_FILE="tests/R3_project_system/test_r3_batch1_1_1_command_activation_fix.py"
PKG_FILE="vscode-extension/package.json"

if [ ! -f "$TEST_FILE" ]; then
  echo "ERROR: Missing $TEST_FILE"
  exit 1
fi

if [ ! -f "$PKG_FILE" ]; then
  echo "ERROR: Missing $PKG_FILE"
  exit 1
fi

mkdir -p "$BACKUP/tests/R3_project_system" "$BACKUP/vscode-extension"
cp -a "$TEST_FILE" "$BACKUP/$TEST_FILE"
cp -a "$PKG_FILE" "$BACKUP/$PKG_FILE"

python3 - <<'PY'
from pathlib import Path
import re

path = Path("tests/R3_project_system/test_r3_batch1_1_1_command_activation_fix.py")
text = path.read_text(encoding="utf-8")

replacement = '''    # Version is intentionally read from package metadata instead of hardcoded.
    # Release bumps such as 1.1.3 must not break command/activation contract tests.
    assert isinstance(pkg["version"], str)
    assert re.match(r"^\\d+\\.\\d+\\.\\d+$", pkg["version"])'''

text = re.sub(
    r'    assert pkg\["version"\] == "[0-9]+\.[0-9]+\.[0-9]+"',
    replacement,
    text,
)

if "import re" not in text:
    lines = text.splitlines()
    insert_at = 0
    while insert_at < len(lines) and (lines[insert_at].startswith("import ") or lines[insert_at].startswith("from ")):
        insert_at += 1
    lines.insert(insert_at, "import re")
    text = "\n".join(lines) + "\n"

path.write_text(text, encoding="utf-8")
PY

python3 -m pytest -q tests/R3_project_system/test_r3_batch1_1_1_command_activation_fix.py

cat > "$REPORT/REPORT.md" <<EOF
# R3 Batch F2 — Release Version Contract Fix

Fixed:
- Removed stale hardcoded VS Code extension version expectation from command activation contract test.
- Test now validates semantic version format instead of forcing 1.1.2.
- This allows release version 1.1.3 to remain valid.

Validation:
- python3 -m pytest -q tests/R3_project_system/test_r3_batch1_1_1_command_activation_fix.py

Next:
- Run full regression:
  python3 -m pytest -q
EOF

echo "R3 Batch F2 Release Version Contract Fix applied."
echo "Backup: $BACKUP"
echo "Report: $REPORT"
echo "Next run: python3 -m pytest -q"
