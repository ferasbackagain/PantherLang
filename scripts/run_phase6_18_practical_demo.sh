#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD_JSON="$(./panther build examples/phase6_runtime/runtime_demo.panther --out /tmp/panther_phase6_18_runtime_demo.sh)"
echo "$BUILD_JSON" | grep -q '"ok": true'

RUN_JSON="$(./panther run examples/phase6_runtime/runtime_demo.panther)"

python3 - "$RUN_JSON" <<'PY'
import json
import sys
data = json.loads(sys.argv[1])
assert data["ok"] is True
assert "Runtime Bridge test" in data["stdout"]
assert "PANTHERLANG" in data["stdout"]
assert "0.6.18" in data["stdout"]
assert "42" in data["stdout"]
assert "Hello from Panther run" in data["stdout"]
assert "Phase 6.18" in data["stdout"]
print("demo=phase6.18-runtime-bridge")
print("ok=true")
print("panther_build=true")
print("panther_run=true")
print("panther_test=true")
print("artifact_runs=true")
PY

./panther test examples/phase6_runtime/runtime_demo.panther >/tmp/panther_phase6_18_test.log
grep -q 'Panther test passed' /tmp/panther_phase6_18_test.log
rm -f /tmp/panther_phase6_18_runtime_demo.sh
