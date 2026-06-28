#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 8.4 PRO - Standard Library Foundation"
echo "============================================================"

mkdir -p stdlib/core stdlib/io stdlib/math stdlib/string examples/phase8_stdlib scripts tests/phase8_4 docs/phase8

cat > stdlib/core/panther_core.py <<'PY'
def version():
    return "0.8.4"

def identity(value):
    return value

def is_ready():
    return True
PY

cat > stdlib/io/panther_io.py <<'PY'
def println(value):
    return str(value)

def read_text(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()
PY

cat > stdlib/math/panther_math.py <<'PY'
def add(a,b):
    return a+b

def multiply(a,b):
    return a*b

def clamp(value, low, high):
    return max(low, min(high, value))
PY

cat > stdlib/string/panther_string.py <<'PY'
def upper(value):
    return str(value).upper()

def lower(value):
    return str(value).lower()

def contains(value, part):
    return str(part) in str(value)
PY

cat > stdlib/manifest.json <<'EOF'
{
  "name": "PantherLang Standard Library Foundation",
  "phase": "8.4",
  "version": "0.8.4",
  "modules": ["core", "io", "math", "string"],
  "status": "foundation"
}
EOF

cat > examples/phase8_stdlib/stdlib_demo.panther <<'EOF'
module panther.stdlib.demo

print "Phase 8.4 Standard Library Foundation"
EOF

cat > docs/phase8/PHASE_8_4_STATUS.md <<'EOF'
# Phase 8.4 — Standard Library Foundation

Completed:
- stdlib/core
- stdlib/io
- stdlib/math
- stdlib/string
- stdlib manifest
- practical Panther run demo
- Python module verification
EOF

cat > scripts/verify_phase8_4_standard_library.sh <<'EOF'
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
EOF
chmod +x scripts/verify_phase8_4_standard_library.sh

echo "[phase8.4] Running verification..."
bash scripts/verify_phase8_4_standard_library.sh

echo "============================================================"
echo " Phase 8.4 COMPLETE"
echo " Next: Phase 8.5 Documentation Generator"
echo "============================================================"
