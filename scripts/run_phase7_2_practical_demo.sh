#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

RUN_OUT="$(./panther run examples/phase7_cli/cli_run_demo.panther)"
echo "$RUN_OUT" | grep -q 'Panther CLI run works'
echo "$RUN_OUT" | grep -q 'PantherLang'
echo "$RUN_OUT" | grep -q 'Phase 7.2 CLI run foundation'

./panther check examples/phase7_cli/cli_run_demo.panther | grep -q 'check passed'

./panther build examples/phase7_cli/cli_run_demo.panther --out /tmp/panther_phase7_2_build.sh | grep -q 'build complete'
bash /tmp/panther_phase7_2_build.sh | grep -q 'Phase 7.2 CLI run foundation'
rm -f /tmp/panther_phase7_2_build.sh

echo "demo=phase7.2-cli-run"
echo "ok=true"
echo "panther_run=true"
echo "panther_build=true"
echo "panther_check=true"
echo "artifact_runs=true"
