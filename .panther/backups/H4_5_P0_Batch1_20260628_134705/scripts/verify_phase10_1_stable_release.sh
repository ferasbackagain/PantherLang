#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 10.1 Stable Release Verification"
echo "============================================================"

test -f VERSION
test -f STABLE_RELEASE.md
test -f stable/stable_manifest.json
test -f docs/phase10/PHASE_10_1_STATUS.md
test -f examples/phase10_stable/stable_demo.panther
echo "✅ structure tests passed"

grep -q '1.0.0-rc1' VERSION
grep -q 'PantherLang 1.0.0-rc1' STABLE_RELEASE.md
echo "✅ version freeze tests passed"

python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("stable/stable_manifest.json").read_text())
assert m["phase"] == "10.1"
assert m["version"] == "1.0.0-rc1"
assert m["status"] == "stable-release-preparation"
assert m["cli_command"] == "Panther"
assert m["backward_compatibility"] is True
assert m["network_required"] is False
assert "production_toolchain" in m["required_components"]
print("✅ stable manifest tests passed")
PY

bash scripts/verify_phase9_10_final_toolchain.sh >/tmp/panther_phase10_1_phase9.log
grep -q 'PantherLang Phase 9 is COMPLETE' /tmp/panther_phase10_1_phase9.log
echo "✅ Phase 9 baseline passed"

Panther doctor >/tmp/panther_phase10_1_doctor.log
grep -q 'PantherLang doctor: OK' /tmp/panther_phase10_1_doctor.log
echo "✅ global Panther command smoke test passed"

Panther run examples/phase10_stable/stable_demo.panther >/tmp/panther_phase10_1_run.log
grep -q 'Phase 10.1 Stable Release Preparation' /tmp/panther_phase10_1_run.log
grep -q 'PantherLang 1.0.0-rc1' /tmp/panther_phase10_1_run.log
echo "✅ stable demo run passed"

Panther build examples/phase10_stable/stable_demo.panther --release >/tmp/panther_phase10_1_build.json
grep -q '"ok": true' /tmp/panther_phase10_1_build.json
test -f build/release/stable_demo.sh
bash build/release/stable_demo.sh | grep -q 'PantherLang 1.0.0-rc1'
echo "✅ stable release build passed"

Panther release create --version 1.0.0-rc1 --channel rc --out-dir /tmp/panther_1_0_0_rc1 >/tmp/panther_phase10_1_release.json
grep -q '"ok": true' /tmp/panther_phase10_1_release.json
test -f /tmp/panther_1_0_0_rc1/release.manifest.json
test -f /tmp/panther_1_0_0_rc1.tar.gz
echo "✅ release candidate generation passed"

echo "✅ PantherLang Phase 10.1 Stable Release Preparation verification complete."
