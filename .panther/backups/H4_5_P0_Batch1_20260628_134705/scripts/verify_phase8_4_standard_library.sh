#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 8.4 Standard Library Verification"
echo "============================================================"

test -f stdlib/core/panther_core.py
test -f stdlib/io/panther_io.py
test -f stdlib/math/panther_math.py
test -f stdlib/string/panther_string.py
test -f stdlib/manifest.json
echo "✅ stdlib structure passed"

python3 - <<'PY'
from stdlib.core.panther_core import version, identity, is_ready
from stdlib.math.panther_math import add, multiply, clamp
from stdlib.string.panther_string import upper, lower, contains
from stdlib.io.panther_io import println

assert version() == "0.8.4"
assert identity("Panther") == "Panther"
assert is_ready() is True
assert add(2,3) == 5
assert multiply(4,5) == 20
assert clamp(50, 1, 10) == 10
assert upper("panther") == "PANTHER"
assert lower("PANTHER") == "panther"
assert contains("PantherLang", "Lang") is True
assert println("ok") == "ok"
print("✅ stdlib function tests passed")
PY

./panther run examples/phase8_stdlib/stdlib_demo.panther | grep -q "Phase 8.4 Standard Library Foundation"
echo "✅ Panther runtime bridge passed"

python3 -m py_compile stdlib/core/panther_core.py stdlib/io/panther_io.py stdlib/math/panther_math.py stdlib/string/panther_string.py
echo "✅ python compile passed"

echo "✅ PantherLang Phase 8.4 Standard Library Foundation verification complete."
