#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"; export PYTHONPATH="$ROOT:${PYTHONPATH:-}"; PYTHON_BIN="${PYTHON:-python3}"
echo "== PantherLang Phase 6.4 Professional Verification =="
$PYTHON_BIN - <<'PY64SMOKE'
from language.compiler.type_inference import AdvancedTypeInferenceEngine
result = AdvancedTypeInferenceEngine().analyze_source('fn add(a: Int, b: Int) -> Int { return a + b }\nlet z = add(1, 2)\n')
assert result.ok is True and result.symbols["z"] == "Int" and result.external_api_used is False and result.network_required is False
print("Import/positive smoke: PASS")
PY64SMOKE
if $PYTHON_BIN -m pytest --version >/dev/null 2>&1; then $PYTHON_BIN -m pytest -q tests/phase6_4; else echo "❌ pytest is not installed. Run: python3 -m pip install pytest"; exit 1; fi
scripts/run_phase6_4_practical_demo.sh
$PYTHON_BIN - <<'PY64NEG'
from language.compiler.type_inference import AdvancedTypeInferenceEngine
bad = AdvancedTypeInferenceEngine().analyze_source('let broken: Int = "x"\n')
assert bad.ok is False and any(d.code == "PANTHER-TYPE-064-ASSIGN" for d in bad.diagnostics)
print("Negative test: PASS")
PY64NEG
$PYTHON_BIN - <<'PY64STRESS'
from language.compiler.type_inference import AdvancedTypeInferenceEngine
lines = ['fn add(a: Int, b: Int) -> Int { return a + b }']
for i in range(500): lines.append(f'let stress_{i} = add({i}, {i+1})')
result = AdvancedTypeInferenceEngine().analyze_source('\n'.join(lines))
assert result.ok is True and len(result.symbols) == 500
print("Stress test: PASS")
PY64STRESS
cat > build/reports/phase6_4_verification_summary.json <<'JSON64SUMMARY'
{"phase":"6.4","name":"Advanced Type Inference","version":"0.6.4-advanced-type-inference","status":"passed_when_this_script_exits_zero","external_api_used":false,"network_required":false}
JSON64SUMMARY
echo "✅ Phase 6.4 verification completed successfully."
