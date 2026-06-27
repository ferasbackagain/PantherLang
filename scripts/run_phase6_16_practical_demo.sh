#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="/tmp/panther_phase6_16_module_$$.sh"
REPORT="$(./panther compile examples/phase6_modules/module_demo.panther --out "$OUT")"
python3 - "$REPORT" "$OUT" <<'PY'
import json, subprocess, sys
from pathlib import Path
report = json.loads(sys.argv[1]); out = Path(sys.argv[2])
assert report["ok"] is True and out.exists()
assert any(item["op"] == "DECLARE_MODULE" for item in report["ir"])
assert any(item["op"] == "IMPORT_MODULE" for item in report["ir"])
proc = subprocess.run([str(out)], text=True, capture_output=True)
assert proc.returncode == 0
assert "Module declaration test" in proc.stdout
assert "Panther Module System" in proc.stdout
assert "0.6.16" in proc.stdout
assert "Phase 6.16 modules" in proc.stdout
print("demo=phase6.16-modules")
print("ok=true")
print("module_declaration=true")
print("imports=true")
print("artifact_runs=true")
PY
rm -f "$OUT"
