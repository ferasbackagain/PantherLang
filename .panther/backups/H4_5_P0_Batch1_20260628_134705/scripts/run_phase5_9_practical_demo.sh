#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

REG="/tmp/panther_phase5_9_demo_registry_$$"
OUT="$(python3 language/packages/runtime/package_manager.py --registry "$REG" demo)"

python3 - "$OUT" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert data["phase"] == "5.9"
assert data["demo"] == "ai-package-ecosystem"
assert data["ok"] is True
assert data["published"] is True
assert data["installed"] is True
assert data["integrity_verified"] is True
assert data["signature_verified"] is True
assert data["sandbox_policy_attached"] is True
assert data["external_api_used"] is False
assert data["network_used"] is False
assert data["deterministic"] is True
print("demo=ai-package-ecosystem")
print("ok=true")
print("published=true")
print("installed=true")
print("integrity_verified=true")
print("signature_verified=true")
print("sandbox_policy_attached=true")
print("external_api_used=false")
print("network_used=false")
print("deterministic=true")
PY

rm -rf "$REG"
