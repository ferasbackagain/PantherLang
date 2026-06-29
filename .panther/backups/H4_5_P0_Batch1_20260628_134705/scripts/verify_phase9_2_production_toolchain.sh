#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 9.2 Production Toolchain Verification"
echo "============================================================"

test -f toolchain/production_toolchain.py
test -f examples/phase9_toolchain/toolchain_demo.panther
test -f docs/phase9/PHASE_9_2_STATUS.md
echo "✅ structure tests passed"

python3 -m py_compile toolchain/production_toolchain.py
echo "✅ python compile passed"

TMP="$(mktemp -d)"
PROJECT_ROOT="$(pwd)"
(
  cd "$TMP"
  "$PROJECT_ROOT/panther" new console ToolchainApp >/dev/null
  cd ToolchainApp

  "$PROJECT_ROOT/panther" build >/tmp/p9_2_debug.json
  grep -q '"ok": true' /tmp/p9_2_debug.json
  grep -q '"profile": "debug"' /tmp/p9_2_debug.json
  test -f build/debug/main.sh
  test -f build/debug/main.build.json
  bash build/debug/main.sh | grep -q "Hello from Panther Console Template"

  "$PROJECT_ROOT/panther" build --release >/tmp/p9_2_release.json
  grep -q '"ok": true' /tmp/p9_2_release.json
  grep -q '"profile": "release"' /tmp/p9_2_release.json
  test -f build/release/main.sh
  test -f build/release/main.build.json
  bash build/release/main.sh | grep -q "Hello from Panther Console Template"

  "$PROJECT_ROOT/panther" toolchain clean >/tmp/p9_2_clean.json
  grep -q '"ok": true' /tmp/p9_2_clean.json
  test ! -d build
)
rm -rf "$TMP"
echo "✅ real external project toolchain tests passed"

./panther build examples/phase9_toolchain/toolchain_demo.panther --release >/tmp/p9_2_repo_release.json
grep -q '"ok": true' /tmp/p9_2_repo_release.json
grep -q '"profile": "release"' /tmp/p9_2_repo_release.json
test -f build/release/toolchain_demo.sh
bash build/release/toolchain_demo.sh | grep -q "Phase 9.2 Production Toolchain"
echo "✅ repository release build test passed"

echo "✅ PantherLang Phase 9.2 Production Toolchain verification complete."
