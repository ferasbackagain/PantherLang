#!/usr/bin/env bash
set -euo pipefail

echo "[verify 6.9] Checking required files ..."
required=(
  "tools/panther-toolchain/panther_toolchain/__init__.py"
  "tools/panther-toolchain/panther_toolchain/targets.py"
  "tools/panther-toolchain/panther_toolchain/resolver.py"
  "tools/panther-toolchain/panther_toolchain/builder.py"
  "tools/panther-toolchain/config/targets.json"
  "tools/panther-toolchain/tests/test_cross_platform_toolchain.py"
  "examples/phase_6_9_toolchain/hello_cross.panther"
  "docs/phase_6/PHASE_6_9_CROSS_PLATFORM_TOOLCHAIN.md"
)
for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: missing $f"
    exit 1
  fi
  echo "OK: $f"
done

echo
mkdir -p build/reports build/cross
export PYTHONPATH="tools/panther-toolchain:${PYTHONPATH:-}"

echo "[verify 6.9] Running Python unit tests ..."
set +e
python3 -m unittest discover -s tools/panther-toolchain/tests -p 'test_*.py' -v 2>&1 | tee build/reports/phase6_9_cross_platform_tests.log
test_status=${PIPESTATUS[0]}
set -e

if [[ "$test_status" -ne 0 ]]; then
  echo "ERROR: Phase 6.9 unit tests failed."
  exit 1
fi

if grep -q "Ran 0 tests" build/reports/phase6_9_cross_platform_tests.log; then
  echo "ERROR: No tests were executed."
  exit 1
fi

python3 - <<'PY'
import json
import re
from pathlib import Path
from panther_toolchain.builder import CrossPlatformBuilder

log = Path("build/reports/phase6_9_cross_platform_tests.log").read_text()
match = re.search(r"Ran (\d+) tests", log)
tests = int(match.group(1)) if match else 0
config = json.loads(Path("tools/panther-toolchain/config/targets.json").read_text())
manifest = CrossPlatformBuilder().emit_manifest("examples/phase_6_9_toolchain/hello_cross.panther", config["targets"])
report = {
    "phase": "6.9",
    "name": "Cross Platform Toolchain",
    "status": "PASS",
    "tests_run": tests,
    "targets": config["targets"],
    "manifest": manifest,
}
Path("build/reports/phase6_9_cross_platform_toolchain_report.json").write_text(json.dumps(report, indent=2))
print("Report written: build/reports/phase6_9_cross_platform_toolchain_report.json")
PY

echo
echo "Phase 6.9 cross-platform toolchain verification completed successfully."
