#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.2 PRO CLI Run Verification FAST"
echo "============================================================"

test -f cli/panther_cli_v2.py
test -f examples/phase7_cli/cli_run_demo.panther
test -x scripts/run_phase7_2_practical_demo.sh
echo "✅ structure tests passed"

./panther doctor | grep -q 'Panther CLI v2: OK'
echo "✅ CLI doctor tests passed"

./panther run examples/phase7_cli/cli_run_demo.panther | grep -q 'Phase 7.2 CLI run foundation'
echo "✅ panther run tests passed"

./panther check examples/phase7_cli/cli_run_demo.panther | grep -q 'check passed'
echo "✅ panther check tests passed"

./panther build examples/phase7_cli/cli_run_demo.panther --out /tmp/panther_phase7_2_verify_build.sh | grep -q 'build complete'
bash /tmp/panther_phase7_2_verify_build.sh | grep -q 'Phase 7.2 CLI run foundation'
rm -f /tmp/panther_phase7_2_verify_build.sh
echo "✅ panther build tests passed"

python3 -m py_compile cli/panther_cli_v2.py
echo "✅ python compile tests passed"

echo "✅ PantherLang Phase 7.2 CLI Run Foundation verification complete."
