#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 9.1 Production Build Verification"
echo "============================================================"

test -f build_system/build_manifest.py
test -f examples/phase9_build/production_build_demo.panther
test -f docs/phase9/PHASE_9_1_STATUS.md
echo "✅ structure tests passed"

python3 -m py_compile build_system/build_manifest.py cli/panther_cli_v2.py
echo "✅ python compile passed"

TMP="$(mktemp -d)"
(
  cd "$TMP"
  Panther new console BuildApp >/dev/null
  cd BuildApp
  Panther build >/tmp/p9_build.out
  grep -q "build complete" /tmp/p9_build.out
  grep -q "mode: debug" /tmp/p9_build.out
  test -f build/main.sh
  test -f build/build_manifest.json
  bash build/main.sh | grep -q "Hello from Panther Console Template"

  Panther build --release >/tmp/p9_release.out
  grep -q "mode: release" /tmp/p9_release.out
)
rm -rf "$TMP"
echo "✅ real external project build tests passed"

Panther run examples/phase9_build/production_build_demo.panther | grep -q "Phase 9.1 Production Build System"
echo "✅ runtime bridge passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase9_1 >/tmp/panther_phase9_1_pytest.log
  echo "✅ pytest suite passed"
fi

echo "✅ PantherLang Phase 9.1 Production Build System verification complete."
