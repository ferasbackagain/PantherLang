#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

OUT_FILE="/tmp/panther_phase5_6_optimized_$$.panther"
OUT="$(python3 language/compiler/ai_optimizer/runtime/ai_optimizer.py demo --out "$OUT_FILE")"

python3 - "$OUT" "$OUT_FILE" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(sys.argv[1])
source = Path(sys.argv[2]).read_text()
assert data["phase"] == "5.6"
assert data["demo"] == "ai-optimizing-compiler"
assert data["ok"] is True
assert data["external_api_used"] is False
assert data["deterministic"] is True
assert "constant_folding" in data["passes_applied"]
assert "let_propagation" in data["passes_applied"]
assert "dead_print_elimination" in data["passes_applied"]
assert "let x = 14" in source
assert "print 14" in source
assert 'print ""' not in source
print("demo=ai-optimizing-compiler")
print("ok=true")
print("external_api_used=false")
print("deterministic=true")
print("contains=let x = 14")
print("contains=print 14")
print('not_contains=print ""')
PY

rm -f "$OUT_FILE"
