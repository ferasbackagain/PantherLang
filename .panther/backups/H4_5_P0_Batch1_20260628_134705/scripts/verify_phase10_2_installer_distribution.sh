#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 10.2 Installer & Distribution Verification"
echo "============================================================"

test -x installers/linux/install_panther.sh
test -x installers/linux/uninstall_panther.sh
test -x installers/macos/install_panther.command
test -f installers/windows/install_panther.ps1
test -f distribution/distribution_manifest.json
test -f docs/phase10/PHASE_10_2_STATUS.md
test -f examples/phase10_distribution/distribution_demo.panther
echo "✅ installer structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("distribution/distribution_manifest.json").read_text())
assert m["phase"] == "10.2"
assert m["version"] == "1.0.0-rc1"
assert m["status"] == "installer-distribution-ready"
assert m["global_command"] == "Panther"
assert "linux" in m["installers"]
assert "windows" in m["installers"]
assert "macos" in m["installers"]
print("✅ distribution manifest tests passed")
PY

grep -q '/usr/local/bin/Panther' installers/linux/install_panther.sh
grep -q '/usr/local/bin/Panther' installers/macos/install_panther.command
grep -q 'Panther.cmd' installers/windows/install_panther.ps1
echo "✅ installer content tests passed"

Panther doctor >/tmp/panther_phase10_2_doctor.log
grep -q 'PantherLang doctor: OK' /tmp/panther_phase10_2_doctor.log
echo "✅ global Panther command test passed"

Panther run examples/phase10_distribution/distribution_demo.panther >/tmp/panther_phase10_2_run.log
grep -q 'Phase 10.2 Installer & Distribution' /tmp/panther_phase10_2_run.log
grep -q 'Panther global installer ready' /tmp/panther_phase10_2_run.log
echo "✅ distribution demo run passed"

Panther build examples/phase10_distribution/distribution_demo.panther --release >/tmp/panther_phase10_2_build.json
grep -q '"ok": true' /tmp/panther_phase10_2_build.json
test -f build/release/distribution_demo.sh
bash build/release/distribution_demo.sh | grep -q 'Phase 10.2 Installer & Distribution'
echo "✅ distribution release build passed"

rm -rf /tmp/panther_dist_10_2 /tmp/panther_dist_10_2.tar.gz
mkdir -p /tmp/panther_dist_10_2
cp -a installers distribution VERSION STABLE_RELEASE.md /tmp/panther_dist_10_2/
tar -czf /tmp/panther_dist_10_2.tar.gz -C /tmp panther_dist_10_2
tar -tzf /tmp/panther_dist_10_2.tar.gz | grep -q 'installers/linux/install_panther.sh'
tar -tzf /tmp/panther_dist_10_2.tar.gz | grep -q 'distribution/distribution_manifest.json'
echo "✅ distribution archive tests passed"

echo "✅ PantherLang Phase 10.2 Installer & Distribution verification complete."
