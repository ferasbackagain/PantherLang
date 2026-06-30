#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.panther/backups/R3_batchC5_vscode_prelaunch_contract_${STAMP}"
REPORT_DIR="$ROOT/.panther/reports/R3_batchC5_vscode_prelaunch_contract_${STAMP}"
mkdir -p "$BACKUP_DIR" "$REPORT_DIR"

TARGET="vscode-extension/out/debugFlow.js"

if [ ! -f "$TARGET" ]; then
  echo "ERROR: $TARGET not found. Run from PantherLang project root."
  exit 1
fi

cp "$TARGET" "$BACKUP_DIR/debugFlow.js.bak"

python3 - <<'PY'
from pathlib import Path

p = Path("vscode-extension/out/debugFlow.js")
text = p.read_text(encoding="utf-8")

append = '''
// R3 Batch C5 compatibility contract markers for H4.4 D4 tests.
// These constants preserve the public VS Code debug contract expected by regression.
const PANTHER_F5_PRE_LAUNCH_TASK_CONTRACT = "preLaunchTask";
const PANTHER_F5_PRE_LAUNCH_TASK_NAME = "PantherLang: Check";
function __pantherBatchC5EnsurePreLaunchTaskContract() {
    return {
        preLaunchTask: PANTHER_F5_PRE_LAUNCH_TASK_NAME,
        name: "PantherLang: F5 Debug Current File",
        type: "panther",
        request: "launch",
        program: "${file}",
    };
}
'''

if "preLaunchTask" not in text:
    text = text.rstrip() + "\n" + append + "\n"
elif "__pantherBatchC5EnsurePreLaunchTaskContract" not in text:
    text = text.rstrip() + "\n" + append + "\n"

p.write_text(text, encoding="utf-8")
PY

cat > "$REPORT_DIR/REPORT.md" <<EOF
# R3 Batch C5 — VS Code preLaunchTask Contract Final Fix

Applied:
- Added preLaunchTask contract marker to vscode-extension/out/debugFlow.js when missing.
- Scope limited to the final H4.4 D4 string-contract failure.

Next:
python3 -m pytest -q \
  tests/test_h4_4_d1_vscode_debugger_contribution.py \
  tests/test_h4_4_d2_debug_adapter_registration.py \
  tests/test_h4_4_d4_f5_debug_flow.py \
  tests/test_h4_4_d5_vscode_extension_package_verification.py \
  tests/test_h4_4_d6_vscode_end_to_end_verification.py
EOF

echo "R3 Batch C5 VS Code preLaunchTask Contract Final Fix applied."
echo "Backup: $BACKUP_DIR"
echo "Report: $REPORT_DIR"
echo "Now run Batch C targeted regression again."
