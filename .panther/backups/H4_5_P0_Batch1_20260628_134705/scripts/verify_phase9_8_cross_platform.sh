#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 9.8 Cross-Platform Verification"
echo "============================================================"
test -f toolchain/cross_platform/cross_platform_toolchain.py
echo "✅ structure tests passed"
python3 -m py_compile toolchain/cross_platform/cross_platform_toolchain.py
echo "✅ python compile passed"

mkdir -p /tmp/p98
./panther xbuild examples/phase9_cross_platform/cross_demo.panther --target linux-x64 --out-dir /tmp/p98 >/tmp/l.json
grep -q '"ok": true' /tmp/l.json
test -f /tmp/p98/cross_demo.sh

./panther xbuild examples/phase9_cross_platform/cross_demo.panther --target windows-x64 --out-dir /tmp/p98 >/tmp/w.json
grep -q '"ok": true' /tmp/w.json
test -f /tmp/p98/cross_demo.bat

./panther xbuild examples/phase9_cross_platform/cross_demo.panther --target macos-arm64 --out-dir /tmp/p98 >/tmp/m.json
grep -q '"ok": true' /tmp/m.json
test -f /tmp/p98/cross_demo.command

echo "✅ linux target passed"
echo "✅ windows target passed"
echo "✅ macOS target passed"
echo "✅ PantherLang Phase 9.8 Cross-Platform Toolchain verification complete."
