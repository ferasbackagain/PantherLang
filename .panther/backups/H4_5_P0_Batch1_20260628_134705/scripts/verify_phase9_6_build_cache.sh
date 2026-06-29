#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 9.6 Build Cache Verification"
echo "============================================================"

test -f toolchain/cache/build_cache.py
test -f toolchain/cache/cache_cli.py
test -f examples/phase9_build_cache/build_cache_demo.panther
echo "✅ structure tests passed"

python3 -m py_compile toolchain/cache/build_cache.py toolchain/cache/cache_cli.py
echo "✅ python compile passed"

TMP="$(mktemp -d)"
PROJECT_ROOT="$(pwd)"
(
  cd "$TMP"
  "$PROJECT_ROOT/panther" new console CacheApp >/dev/null
  cd CacheApp

  "$PROJECT_ROOT/panther" cache clear >/tmp/p96_clear.json
  grep -q '"ok": true' /tmp/p96_clear.json

  "$PROJECT_ROOT/panther" cache status src/main.panther --profile debug >/tmp/p96_status1.json
  grep -q '"changed": true' /tmp/p96_status1.json
  grep -q '"hit": false' /tmp/p96_status1.json

  "$PROJECT_ROOT/panther" build >/tmp/p96_build.json
  grep -q '"ok": true' /tmp/p96_build.json

  "$PROJECT_ROOT/panther" cache update src/main.panther --profile debug --artifact build/debug/main.sh >/tmp/p96_update.json
  grep -q '"updated": true' /tmp/p96_update.json

  "$PROJECT_ROOT/panther" cache status src/main.panther --profile debug >/tmp/p96_status2.json
  grep -q '"changed": false' /tmp/p96_status2.json
  grep -q '"hit": true' /tmp/p96_status2.json

  echo 'print "changed"' >> src/main.panther
  "$PROJECT_ROOT/panther" cache status src/main.panther --profile debug >/tmp/p96_status3.json
  grep -q '"changed": true' /tmp/p96_status3.json
)
rm -rf "$TMP"
echo "✅ real external project cache tests passed"

./panther build examples/phase9_build_cache/build_cache_demo.panther --release >/tmp/p96_repo_build.json
grep -q '"ok": true' /tmp/p96_repo_build.json
test -f build/release/build_cache_demo.sh
bash build/release/build_cache_demo.sh | grep -q "Phase 9.6 Build Cache Integration"
echo "✅ release build passed"

echo "✅ PantherLang Phase 9.6 Build Cache Integration verification complete."
