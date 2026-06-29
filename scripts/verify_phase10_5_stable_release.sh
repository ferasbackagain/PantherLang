#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 10.5 Stable Release Verification FAST"
echo "============================================================"

test -f VERSION
test -f release/stable/stable_manifest.json
test -f docs/phase10/PHASE_10_5_STATUS.md
test -f examples/phase10_release/stable_release.panther
echo "✅ structure tests passed"

grep -q '^1.0.0$' VERSION
grep -q '"version":"1.0.0"' release/stable/stable_manifest.json
grep -q '"status":"stable"' release/stable/stable_manifest.json
echo "✅ stable version tests passed"

Panther doctor >/tmp/p105_doctor.log
grep -q 'PantherLang doctor: OK' /tmp/p105_doctor.log
echo "✅ global Panther command passed"

Panther run examples/phase10_release/stable_release.panther >/tmp/p105run.log
grep -q 'PantherLang Stable Release 1.0' /tmp/p105run.log
grep -q 'Version 1.0.0' /tmp/p105run.log
echo "✅ runtime passed"

Panther check examples/phase10_release/stable_release.panther >/tmp/p105check.log
grep -q 'check passed' /tmp/p105check.log
echo "✅ check passed"

Panther build examples/phase10_release/stable_release.panther --release >/tmp/p105build.json
grep -q '"ok": true' /tmp/p105build.json
test -f build/release/stable_release.sh
bash build/release/stable_release.sh | grep -q 'PantherLang Stable Release 1.0'
echo "✅ release build passed"

Panther fmt examples/phase10_release/stable_release.panther >/tmp/p105fmt.log
grep -q 'PantherLang Stable Release 1.0' /tmp/p105fmt.log
echo "✅ formatter passed"

Panther debug examples/phase10_release/stable_release.panther --breakpoint 1 >/tmp/p105debug.json
grep -q '"phase": "8.9"' /tmp/p105debug.json
echo "✅ debugger passed"

Panther registry list >/tmp/p105registry.json
grep -q '"ok": true' /tmp/p105registry.json
echo "✅ registry passed"

Panther release create --version 1.0.0 --channel stable --out-dir /tmp/panther_1_0_0 >/tmp/p105rel.json
grep -q '"ok": true' /tmp/p105rel.json
test -f /tmp/panther_1_0_0.tar.gz
echo "✅ stable release package passed"

echo "✅ PantherLang Phase 10.5 Stable Release verification complete."
echo "✅ PantherLang 1.0.0 STABLE RELEASE COMPLETE."
