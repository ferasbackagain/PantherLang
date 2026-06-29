#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang H1 Enterprise Testing Verification"
echo "============================================================"

test -f hardening/H1/H1_MANIFEST.json
test -f qa/enterprise_tests/enterprise_suite.py
test -f fuzz_tests/panther_fuzzer.py
test -f stress_tests/stress_runner.py
test -f benchmarks/panther_benchmark.py
test -x scripts/run_H1_enterprise_suite.sh
echo "✅ H1 structure tests passed"

python3 -m py_compile \
  qa/enterprise_tests/enterprise_suite.py \
  fuzz_tests/panther_fuzzer.py \
  stress_tests/stress_runner.py \
  benchmarks/panther_benchmark.py
echo "✅ H1 python compile tests passed"

python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("hardening/H1/H1_MANIFEST.json").read_text())
assert m["stage"] == "H1"
assert m["version"] == "1.0.0"
assert "massive_regression" in m["scope"]
assert m["network_required"] is False
print("✅ H1 manifest tests passed")
PY

bash scripts/verify_phase10_5_stable_release.sh >/tmp/panther_H1_phase10_5.log
grep -q 'PantherLang 1.0.0 STABLE RELEASE COMPLETE' /tmp/panther_H1_phase10_5.log
echo "✅ PantherLang 1.0 stable baseline passed"

Panther run examples/H1/h1_enterprise_demo.panther >/tmp/panther_H1_demo.log
grep -q 'PantherLang H1 Enterprise Testing' /tmp/panther_H1_demo.log
grep -q 'Validation Ready' /tmp/panther_H1_demo.log
echo "✅ H1 demo run passed"

bash scripts/run_H1_enterprise_suite.sh >/tmp/panther_H1_suite.log
grep -q 'H1_ENTERPRISE_SUITE_COMPLETE=true' /tmp/panther_H1_suite.log
test -f reports/H1/enterprise_suite.json
test -f reports/H1/fuzz_suite.json
test -f reports/H1/stress_suite.json
test -f reports/H1/benchmark_suite.json
test -f reports/H1/H1_VALIDATION_REPORT.md
echo "✅ H1 enterprise suite passed"

grep -q 'Status: PASSED' reports/H1/H1_VALIDATION_REPORT.md
echo "✅ H1 validation report passed"

echo "✅ PantherLang H1 Enterprise Testing COMPLETE."
