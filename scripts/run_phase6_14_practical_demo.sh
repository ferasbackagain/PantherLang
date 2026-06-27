#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="/tmp/panther_phase6_14_fn_$$.sh"
REPORT="$(./panther compile examples/phase6_functions/function_demo.panther --out "$OUT")"
python3 - "$REPORT" "$OUT" <<'PY'
import json, subprocess, sys
from pathlib import Path
report = json.loads(sys.argv[1]); out = Path(sys.argv[2])
assert report["ok"] is True and out.exists()
proc = subprocess.run([str(out)], text=True, capture_output=True)
assert proc.returncode == 0
assert "Hello from function" in proc.stdout
assert "PantherLang" in proc.stdout
assert "Phase 6.14 functions" in proc.stdout
print("demo=phase6.14-functions")
print("ok=true")
print("function_declaration=true")
print("function_call=true")
print("parameters=true")
print("artifact_runs=true")
PY
rm -f "$OUT"
