#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="/tmp/panther_phase6_13_loop_$$.sh"
REPORT="$(./panther compile examples/phase6_loops/for_loop_demo.panther --out "$OUT")"
python3 - "$REPORT" "$OUT" <<'PY'
import json, subprocess, sys
from pathlib import Path
report = json.loads(sys.argv[1]); out = Path(sys.argv[2])
assert report["ok"] is True and out.exists()
proc = subprocess.run([str(out)], text=True, capture_output=True)
assert proc.returncode == 0
assert proc.stdout.count("Loop iteration") == 3
assert "Phase 6.13 loops" in proc.stdout
print("demo=phase6.13-loops")
print("ok=true")
print("for_loop=true")
print("range_loop=true")
print("artifact_runs=true")
PY
rm -f "$OUT"
