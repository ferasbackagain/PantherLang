#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP="$ROOT/.panther/backups/R3_batchF2b_release_version_contract_$STAMP"
REPORT="$ROOT/.panther/reports/R3_batchF2b_release_version_contract_$STAMP"

mkdir -p "$BACKUP/tests/R3_project_system" "$REPORT"

TEST_FILE="tests/R3_project_system/test_r3_batch1_1_1_command_activation_fix.py"

if [ ! -f "$TEST_FILE" ]; then
  echo "ERROR: Missing $TEST_FILE"
  exit 1
fi

cp -a "$TEST_FILE" "$BACKUP/$TEST_FILE"

python3 - <<'PY'
from pathlib import Path

path = Path("tests/R3_project_system/test_r3_batch1_1_1_command_activation_fix.py")
text = path.read_text(encoding="utf-8")

if "import re" not in text:
    lines = text.splitlines()
    insert_at = 0
    while insert_at < len(lines) and (lines[insert_at].startswith("import ") or lines[insert_at].startswith("from ")):
        insert_at += 1
    lines.insert(insert_at, "import re")
    text = "\n".join(lines) + "\n"

old = '    assert pkg["version"] == "1.1.2"'
new = (
    '    # Version must be valid semver; release bumps must not break this contract.\n'
    '    assert isinstance(pkg["version"], str)\n'
    '    assert re.match(r"^\\d+\\.\\d+\\.\\d+$", pkg["version"])'
)

if old not in text:
    raise SystemExit("Expected hardcoded version assertion was not found; refusing unsafe patch.")

text = text.replace(old, new)
path.write_text(text, encoding="utf-8")
PY

python3 -m pytest -q tests/R3_project_system/test_r3_batch1_1_1_command_activation_fix.py

cat > "$REPORT/REPORT.md" <<EOF
# R3 Batch F2b — Release Version Contract Fix

Fixed stale hardcoded VS Code extension version assertion.

Result:
- package.json may remain at 1.1.3
- test validates semver format instead of forcing 1.1.2

Next:
- python3 -m pytest -q
EOF

echo "R3 Batch F2b Release Version Contract Fix applied."
echo "Backup: $BACKUP"
echo "Report: $REPORT"
echo "Next run: python3 -m pytest -q"
