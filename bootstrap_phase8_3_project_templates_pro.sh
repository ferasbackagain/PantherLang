#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 8.3 PRO - Project Templates"
echo "============================================================"

mkdir -p templates/console templates/web templates/api examples/phase8_templates scripts docs/phase8

cat > templates/console/main.panther <<'EOF'
print "Hello from Panther Console Template"
EOF

cat > templates/web/main.panther <<'EOF'
print "Hello from Panther Web Template"
EOF

cat > templates/api/main.panther <<'EOF'
print "Hello from Panther API Template"
EOF

mkdir -p project_templates

cat > project_templates/template_cli.py <<'PY'
#!/usr/bin/env python3
from pathlib import Path
import shutil
import argparse

parser=argparse.ArgumentParser()
parser.add_argument("kind", choices=["console","web","api"])
parser.add_argument("name")
args=parser.parse_args()

root=Path(__file__).resolve().parents[1]
src=root/"templates"/args.kind
dst=Path.cwd()/args.name
dst.mkdir(parents=True, exist_ok=True)
(dst/"src").mkdir(exist_ok=True)
shutil.copy(src/"main.panther", dst/"src"/"main.panther")
(dst/"panther.toml").write_text(f'[project]\nname="{args.name}"\ntemplate="{args.kind}"\n')
print(f"Created {dst}")
PY
chmod +x project_templates/template_cli.py

if ! grep -q 'project_templates/template_cli.py' panther; then
python3 - <<'PY'
from pathlib import Path
p=Path("panther")
t=p.read_text()
needle='  package)\n'
ins='  new)\n    shift\n    python3 "$ROOT/project_templates/template_cli.py" "$@"\n    ;;\n\n'
if ins not in t:
    t=t.replace(needle, ins+needle)
p.write_text(t)
PY
chmod +x panther
fi

cat > examples/phase8_templates/template_demo.panther <<'EOF'
print "Phase 8.3 Project Templates"
EOF

cat > scripts/verify_phase8_3_project_templates.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 8.3 Project Templates Verification"
echo "============================================================"
test -d templates/console
test -d templates/web
test -d templates/api
echo "✅ template structure passed"
TMP=$(mktemp -d)
(
cd "$TMP"
"$OLDPWD"/panther new console DemoApp >/dev/null
test -f DemoApp/src/main.panther
test -f DemoApp/panther.toml
)
rm -rf "$TMP"
echo "✅ project generation passed"
./panther run examples/phase8_templates/template_demo.panther | grep -q "Phase 8.3 Project Templates"
echo "✅ runtime bridge passed"
python3 -m py_compile project_templates/template_cli.py
echo "✅ python compile passed"
echo "✅ PantherLang Phase 8.3 Project Templates verification complete."
EOF
chmod +x scripts/verify_phase8_3_project_templates.sh

bash scripts/verify_phase8_3_project_templates.sh

echo "============================================================"
echo " Phase 8.3 COMPLETE"
echo " Next: Phase 8.4 Standard Library Foundation"
echo "============================================================"
