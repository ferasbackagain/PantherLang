#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p reports/H2

python3 native_executables/native_builder.py --out-dir dist/native > reports/H2/native_build_all.json
grep -q '"ok": true' reports/H2/native_build_all.json

test -x dist/native/linux-x64/Panther
test -f dist/native/windows-x64/Panther.cmd
test -x dist/native/macos-arm64/Panther.command

dist/native/linux-x64/Panther doctor > reports/H2/linux_native_doctor.log
grep -q 'PantherLang doctor: OK' reports/H2/linux_native_doctor.log

dist/native/linux-x64/Panther run examples/H2/h2_native_demo.panther > reports/H2/linux_native_run.log
grep -q 'PantherLang H2 Native Executables' reports/H2/linux_native_run.log
grep -q 'Native launcher validation' reports/H2/linux_native_run.log

dist/native/linux-x64/Panther build examples/H2/h2_native_demo.panther --release > reports/H2/linux_native_build.json
grep -q '"ok": true' reports/H2/linux_native_build.json
test -f build/release/h2_native_demo.sh

cat > reports/H2/H2_NATIVE_REPORT.md <<'REPORT'
# PantherLang H2 Native Executables Report

Status: PASSED

Targets generated:
- Linux x64 launcher
- Windows x64 command launcher
- macOS ARM64 command launcher

Result:
PantherLang H2 Native Executables COMPLETE.

Note:
This stage establishes native launcher packaging. Fully self-contained Python-free binaries are the next maturation path for later hardening.
REPORT

echo "H2_NATIVE_SUITE_COMPLETE=true"
