#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 8.6 Formatter Verification"
echo "============================================================"

test -f tools/formatter/panther_fmt.py
echo "✅ structure tests passed"

TMP=$(mktemp)
printf 'print "x"    \nprint "y"\t\n' > "$TMP"

./panther fmt "$TMP" --write >/dev/null
python3 - <<PY
from pathlib import Path
p=Path("$TMP")
for line in p.read_text().splitlines():
    assert line==line.rstrip()
print("ok")
PY
rm -f "$TMP"
echo "✅ formatter tests passed"

./panther run examples/phase8_formatter/format_demo.panther | grep -q "Phase 8.6 Formatter"
echo "✅ runtime bridge tests passed"

python3 -m py_compile tools/formatter/panther_fmt.py
echo "✅ python compile passed"

echo "✅ PantherLang Phase 8.6 Formatter verification complete."
