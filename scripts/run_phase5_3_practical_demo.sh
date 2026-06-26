#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

STORE="/tmp/panther_phase5_3_practical_demo_store_$$.json"
rm -f "$STORE"

OUT="$(python3 language/memory/runtime/memory_runtime.py --store "$STORE" demo --reset)"

python3 - "$OUT" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
assert data["demo"] == "phase5.3-memory-context"
assert data["ok"] is True
assert data["record_count"] >= 1
assert data["external_api_used"] is False
assert "Memory and Context Engine" in data["practical_result"]

print("demo=phase5.3-memory-context")
print("ok=true")
print(f"record_count={data['record_count']}")
print("external_api_used=false")
print("contains=Memory and Context Engine")
PY

rm -f "$STORE"
