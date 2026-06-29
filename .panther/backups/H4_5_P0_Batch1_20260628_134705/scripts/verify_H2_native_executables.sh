#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang H2 Native Executables Verification"
echo "============================================================"

test -f hardening/H2/H2_MANIFEST.json
test -f native_executables/native_builder.py
test -f installers/native/install_native_linux.sh
test -f examples/H2/h2_native_demo.panther
test -x scripts/run_H2_native_suite.sh
echo "✅ H2 structure tests passed"

python3 -m py_compile native_executables/native_builder.py
echo "✅ H2 python compile tests passed"

python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("hardening/H2/H2_MANIFEST.json").read_text())
assert m["stage"] == "H2"
assert m["version"] == "1.0.0"
assert "linux-x64" in m["targets"]
assert "windows-x64" in m["targets"]
assert "macos-arm64" in m["targets"]
assert m["python_free_goal"] is True
print("✅ H2 manifest tests passed")
PY

bash scripts/verify_H1_enterprise_testing.sh >/tmp/panther_H2_H1.log
grep -q 'PantherLang H1 Enterprise Testing COMPLETE' /tmp/panther_H2_H1.log
echo "✅ H1 baseline passed"

bash scripts/run_H2_native_suite.sh >/tmp/panther_H2_suite.log
grep -q 'H2_NATIVE_SUITE_COMPLETE=true' /tmp/panther_H2_suite.log
test -f reports/H2/native_build_all.json
test -f reports/H2/H2_NATIVE_REPORT.md
echo "✅ H2 native suite passed"

grep -q 'Status: PASSED' reports/H2/H2_NATIVE_REPORT.md
echo "✅ H2 validation report passed"

tar -czf /tmp/panther_H2_native_artifacts.tar.gz dist/native installers/native hardening/H2 reports/H2
tar -tzf /tmp/panther_H2_native_artifacts.tar.gz | grep -q 'dist/native/linux-x64/Panther'
tar -tzf /tmp/panther_H2_native_artifacts.tar.gz | grep -q 'dist/native/windows-x64/Panther.cmd'
tar -tzf /tmp/panther_H2_native_artifacts.tar.gz | grep -q 'dist/native/macos-arm64/Panther.command'
echo "✅ H2 native artifact package passed"

echo "✅ PantherLang H2 Native Executables COMPLETE."
