#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

OUT_FILE="/tmp/panther_phase5_5_generated_$$.panther"
OUT="$(python3 language/nlp/runtime/intent_compiler.py demo --out "$OUT_FILE")"

python3 - "$OUT" "$OUT_FILE" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(sys.argv[1])
source = Path(sys.argv[2]).read_text()

assert data["phase"] == "5.5"
assert data["demo"] == "natural-language-to-pantherlang"
assert data["ok"] is True
assert data["intent_kind"] == "function"
assert data["external_api_used"] is False
assert data["deterministic"] is True
assert "fn add" in source
assert "print add(2, 3)" in source

print("demo=natural-language-to-pantherlang")
print("ok=true")
print("intent_kind=function")
print("external_api_used=false")
print("deterministic=true")
print("contains=fn add")
print("contains=print add(2, 3)")
PY

rm -f "$OUT_FILE"
