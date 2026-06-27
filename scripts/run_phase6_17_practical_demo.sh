#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="/tmp/panther_phase6_17_stdlib_$$.sh"
REPORT="$(./panther compile examples/phase6_stdlib/stdlib_demo.panther --out "$OUT")"
python3 - "$REPORT" "$OUT" <<'PY'
import json, subprocess, sys
from pathlib import Path
report = json.loads(sys.argv[1]); out = Path(sys.argv[2])
assert report["ok"] is True and out.exists()
proc = subprocess.run([str(out)], text=True, capture_output=True)
assert proc.returncode == 0
assert "Standard Library test" in proc.stdout
assert "PANTHER" in proc.stdout
assert "panther" in proc.stdout
assert "15" in proc.stdout
assert "21" in proc.stdout
assert "Phase 6.17 stdlib" in proc.stdout
print("demo=phase6.17-stdlib")
print("ok=true")
print("std_text=true")
print("std_math=true")
print("std_io=true")
print("artifact_runs=true")
PY
rm -f "$OUT"
