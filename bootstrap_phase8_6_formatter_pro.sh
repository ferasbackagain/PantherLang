#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 8.6 PRO - Formatter"
echo "============================================================"

mkdir -p tools/formatter examples/phase8_formatter scripts docs/phase8

cat > tools/formatter/panther_fmt.py <<'PY'
#!/usr/bin/env python3
from pathlib import Path
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("source")
parser.add_argument("--write", action="store_true")
args = parser.parse_args()

src = Path(args.source)
text = src.read_text(encoding="utf-8")

formatted = "\n".join(line.rstrip() for line in text.splitlines()) + "\n"

if args.write:
    src.write_text(formatted, encoding="utf-8")
    print(f"formatted:{src}")
else:
    print(formatted, end="")
PY
chmod +x tools/formatter/panther_fmt.py

cat > examples/phase8_formatter/format_demo.panther <<'EOF'
module panther.format

print "Phase 8.6 Formatter"
EOF

python3 - <<'PY'
from pathlib import Path
p=Path("panther")
t=p.read_text()
if 'tools/formatter/panther_fmt.py' not in t:
    needle='  package)\n'
    ins='  fmt)\n    shift\n    python3 "$ROOT/tools/formatter/panther_fmt.py" "$@"\n    ;;\n\n'
    t=t.replace(needle,ins+needle)
    p.write_text(t)
PY
chmod +x panther

cat > scripts/verify_phase8_6_formatter.sh <<'EOF'
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
EOF
chmod +x scripts/verify_phase8_6_formatter.sh

bash scripts/verify_phase8_6_formatter.sh

echo "============================================================"
echo " Phase 8.6 COMPLETE"
echo " Next: Phase 8.7 Language Server Protocol"
echo "============================================================"
