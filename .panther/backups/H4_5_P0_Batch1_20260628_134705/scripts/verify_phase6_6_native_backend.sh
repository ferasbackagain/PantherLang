#!/usr/bin/env bash
set -euo pipefail
echo "Running Phase 6.6 verification"
echo "= PantherLang Phase 6.6 Professional Verification ="
python3 - <<'PY'
from language.compiler.native_backend import TargetRegistry
from language.compiler.integration.native_backend_integration import compile_to_native
assert 'x86_64-unknown-linux-gnu' in TargetRegistry().list_targets()
assert compile_to_native('print 1', module_name='smoke')['success'] is True
print('Imports/positive smoke: PASS')
PY
python3 -m pytest tests/phase6_6 -q && echo "Pytest: PASS"
scripts/run_phase6_6_practical_demo.sh
python3 - <<'PY'
from language.compiler.native_backend import PantherNativeBackend
negative=False
try: PantherNativeBackend().build('', module_name='bad')
except ValueError: negative=True
assert negative
print('Negative tests: PASS')
backend=PantherNativeBackend()
for i in range(80):
    assert backend.build(f'let x = {i}\nprint x', module_name=f'stress_native_{i}').success
print('Stress test: PASS')
PY
mkdir -p build/reports
python3 - <<'PY'
import json, time
from pathlib import Path
summary={"phase":"6.6","name":"Native Backend Integration","status":"PASS","checks":["imports","pytest","demo","negative","stress"],"timestamp":time.time(),"github_push":"postponed until Phase 6.10 full regression"}
Path('build/reports/phase6_6_verification_summary.json').write_text(json.dumps(summary,indent=2,sort_keys=True))
PY
echo "Phase 6.6 verification completed successfully."
