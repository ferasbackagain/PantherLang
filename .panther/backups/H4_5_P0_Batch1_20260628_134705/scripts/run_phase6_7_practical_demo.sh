#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
from language.compiler.ai_optimization import PantherAICompilerOptimizer
source = "\n2 + 3\nagent threat_hunter\nworkflow incident_response\ndead unreachable_branch\nprint result\n"
r=PantherAICompilerOptimizer().optimize_source(source, unit_name='phase6_7_demo')
print('Phase 6.7 demo ok:', r.success)
print('Before cost:', r.before_cost['estimated_runtime_cost'])
print('After cost:', r.after_cost['estimated_runtime_cost'])
print('Nodes after:', r.after_cost['node_count'])
print('Report:', r.report_path)
PY
