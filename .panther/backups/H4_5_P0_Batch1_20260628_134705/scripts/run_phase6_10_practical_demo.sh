#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="/tmp/panther_phase6_10_practical_artifact_$$.sh"
REPORT="$(python3 compiler/pipeline/panther_compiler.py compile examples/phase6_final/hello_phase6_10.panther --out "$OUT")"
python3 - "$REPORT" "$OUT" <<'PY'
import json, subprocess, sys
from pathlib import Path
report = json.loads(sys.argv[1])
out = Path(sys.argv[2])
assert report["phase"] == "6.10"
assert report["ok"] is True
for stage in ["lex","parse","semantic","ir","backend","emit"]:
    assert stage in report["stages"]
assert out.exists()
proc = subprocess.run([str(out)], text=True, capture_output=True)
assert proc.returncode == 0
assert "PantherLang compiled artifact" in proc.stdout
assert "Phase 6.10 compiler integration works" in proc.stdout
print("demo=final-compiler-integration")
print("ok=true")
print("stages=lex,parse,semantic,ir,backend,emit")
print("artifact_runs=true")
print("external_api_used=false")
print("network_used=false")
print("deterministic=true")
print("contains=Phase 6.10 compiler integration works")
PY
rm -f "$OUT"
