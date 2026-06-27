#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

OUT="/tmp/panther_phase6_11_expr_artifact_$$.sh"
REPORT="$(./panther compile examples/phase6_expressions/expressions_demo.panther --out "$OUT")"

python3 - "$REPORT" "$OUT" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

report = json.loads(sys.argv[1])
out = Path(sys.argv[2])
assert report["ok"] is True
assert out.exists()

proc = subprocess.run([str(out)], text=True, capture_output=True)
assert proc.returncode == 0
assert "Phase 6.11 expressions" in proc.stdout
assert "15" in proc.stdout
assert "30" in proc.stdout
assert "true" in proc.stdout

print("demo=phase6.11-expressions")
print("ok=true")
print("arithmetic=true")
print("comparisons=true")
print("variables=true")
print("artifact_runs=true")
PY

rm -f "$OUT"
