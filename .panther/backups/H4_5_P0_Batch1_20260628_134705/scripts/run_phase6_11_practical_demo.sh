#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="/tmp/panther_phase6_11_expr_artifact_$$.sh"
REPORT="$(./panther compile examples/phase6_expressions/expressions_demo.panther --out "$OUT")"
python3 - "$REPORT" "$OUT" <<'PY'
import json, subprocess, sys
from pathlib import Path
r=json.loads(sys.argv[1]); out=Path(sys.argv[2]); assert r['ok'] and out.exists()
p=subprocess.run([str(out)], text=True, capture_output=True); assert p.returncode==0
for x in ['Phase 6.11 expressions','15','30','true']: assert x in p.stdout
print('demo=phase6.11-rev2-expressions')
print('ok=true')
print('arithmetic=true')
print('comparisons=true')
print('variables=true')
print('artifact_runs=true')
PY
rm -f "$OUT"
