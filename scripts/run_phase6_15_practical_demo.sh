#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="/tmp/panther_phase6_15_struct_$$.sh"
REPORT="$(./panther compile examples/phase6_structs/struct_demo.panther --out "$OUT")"
python3 - "$REPORT" "$OUT" <<'PY'
import json, subprocess, sys
from pathlib import Path
report = json.loads(sys.argv[1]); out = Path(sys.argv[2])
assert report["ok"] is True and out.exists()
assert any(item["op"] == "DECLARE_STRUCT" for item in report["ir"])
proc = subprocess.run([str(out)], text=True, capture_output=True)
assert proc.returncode == 0
assert "Struct declaration test" in proc.stdout
assert "Feras" in proc.stdout
assert "Founder" in proc.stdout
assert "Phase 6.15 structs" in proc.stdout
print("demo=phase6.15-structs")
print("ok=true")
print("struct_declaration=true")
print("fields=true")
print("artifact_runs=true")
PY
rm -f "$OUT"
