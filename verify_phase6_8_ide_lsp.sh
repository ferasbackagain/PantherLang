#!/usr/bin/env bash
set -Eeuo pipefail

PHASE="6.8"
REPORT_DIR="build/reports"
REPORT="$REPORT_DIR/phase6_8_lsp_real_tests_report.json"
mkdir -p "$REPORT_DIR"

printf '[verify 6.8] Checking required files ...\n'
required=(
  "tools/panther-lsp/panther_lsp/server.py"
  "tools/panther-lsp/panther_lsp/analyzer.py"
  "tools/panther-lsp/panther_lsp/protocol.py"
  "tools/panther-lsp/tests/test_lsp_core.py"
  "tools/panther-ide/vscode/pantherlang/package.json"
  "tools/panther-ide/vscode/pantherlang/syntaxes/pantherlang.tmLanguage.json"
  "examples/phase_6_8_lsp/hello_lsp.panther"
  "docs/phase_6/PHASE_6_8_IDE_LSP.md"
)

for file in "${required[@]}"; do
  if [[ ! -f "$file" ]]; then
    printf 'FAIL: missing %s\n' "$file"
    exit 1
  fi
  printf 'OK: %s\n' "$file"
done

printf '\n[verify 6.8] Running Python unit tests ...\n'
set +e
TEST_OUTPUT=$(python3 -m unittest discover -s tools/panther-lsp/tests -p 'test_*.py' -v 2>&1)
TEST_STATUS=$?
set -e
printf '%s\n' "$TEST_OUTPUT"

if printf '%s\n' "$TEST_OUTPUT" | grep -q "Ran 0 tests"; then
  printf '\nFAIL: unittest discovered zero tests.\n'
  exit 1
fi

if [[ $TEST_STATUS -ne 0 ]]; then
  printf '\nFAIL: Phase 6.8 unit tests failed.\n'
  exit "$TEST_STATUS"
fi

TEST_COUNT=$(printf '%s\n' "$TEST_OUTPUT" | sed -nE 's/^Ran ([0-9]+) tests?.*/\1/p' | tail -n 1)
if [[ -z "${TEST_COUNT:-}" || "$TEST_COUNT" -lt 1 ]]; then
  printf '\nFAIL: Could not confirm executed test count.\n'
  exit 1
fi

python3 - <<PY
import json
from pathlib import Path
report = {
    "phase": "6.8",
    "name": "IDE & Language Server Protocol",
    "status": "PASS",
    "test_count": int("$TEST_COUNT"),
    "zero_test_guard": "ENABLED",
    "report": "$REPORT",
}
Path("$REPORT").write_text(json.dumps(report, indent=2), encoding="utf-8")
print("Report written:", Path("$REPORT"))
PY

printf '\nPhase 6.8 real LSP verification completed successfully.\n'
