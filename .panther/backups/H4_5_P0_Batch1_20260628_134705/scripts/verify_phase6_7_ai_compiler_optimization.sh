#!/usr/bin/env bash
set -euo pipefail
echo "Running Phase 6.7 verification"
echo "= PantherLang Phase 6.7 Professional Verification ="
python3 - <<'PY'
from language.compiler.ai_optimization import PantherAICompilerOptimizer
from language.compiler.integration.ai_optimizer_integration import optimize_with_ai_compiler
assert PantherAICompilerOptimizer().optimize_source('1 + 2', 'smoke').success is True
assert optimize_with_ai_compiler('agent smoke', 'smoke_adapter')['success'] is True
print('Imports/positive smoke: PASS')
PY
python3 -m pytest tests/phase6_7 -q && echo "Pytest: PASS"
scripts/run_phase6_7_practical_demo.sh
python3 - <<'PY'
from language.compiler.ai_optimization import PantherAICompilerOptimizer
negative=False
try: PantherAICompilerOptimizer().optimize_source('   ')
except ValueError: negative=True
assert negative
print('Negative tests: PASS')
opt=PantherAICompilerOptimizer()
for i in range(120):
    src=f'{i} + {i+1}\nagent stress_{i}\ndead unreachable_{i}'
    r=opt.optimize_source(src, unit_name=f'stress_ai_opt_{i}')
    assert r.success and r.after_cost['node_count'] <= r.before_cost['node_count']
print('Stress test: PASS')
PY
mkdir -p build/reports
python3 - <<'PY'
import json, time
from pathlib import Path
summary={"phase":"6.7","name":"AI Compiler Optimization","status":"PASS","checks":["imports","pytest","demo","negative","stress"],"timestamp":time.time(),"github_push":"postponed until Phase 6.10 full regression"}
Path('build/reports/phase6_7_verification_summary.json').write_text(json.dumps(summary,indent=2,sort_keys=True))
PY
echo "Phase 6.7 verification completed successfully."
