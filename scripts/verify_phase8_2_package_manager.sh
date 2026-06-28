#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 8.2 Package Manager Verification"
echo "============================================================"

test -f package_manager/package_manager.py
test -f package_manager/package_cli.py
test -d package_manager/local_registry
echo "✅ structure tests passed"

TMPDIR="$(mktemp -d)"
PROJECT_ROOT="$(pwd)"
(
  cd "$TMPDIR"
  PYTHONPATH="$PROJECT_ROOT" python3 "$PROJECT_ROOT/package_manager/package_cli.py" init demo_pkg | grep -q "package initialized"
  test -f panther.toml
  PYTHONPATH="$PROJECT_ROOT" python3 "$PROJECT_ROOT/package_manager/package_cli.py" add panther.ai --version 0.1.0 | grep -q "dependency added"
  test -f panther.lock
  PYTHONPATH="$PROJECT_ROOT" python3 "$PROJECT_ROOT/package_manager/package_cli.py" list | grep -q "panther.ai"
  PYTHONPATH="$PROJECT_ROOT" python3 "$PROJECT_ROOT/package_manager/package_cli.py" remove panther.ai | grep -q "dependency removed"
)
rm -rf "$TMPDIR"
echo "✅ package manager CLI tests passed"

./panther package list | grep -q "dependencies"
echo "✅ Panther package bridge tests passed"

./panther run examples/phase8_packages/package_demo.panther | grep -q "Phase 8.2 Package Manager Foundation"
echo "✅ compiler/runtime bridge tests passed"

python3 -m py_compile package_manager/package_manager.py package_manager/package_cli.py
echo "✅ python compile tests passed"

echo "✅ PantherLang Phase 8.2 Package Manager Foundation verification complete."
