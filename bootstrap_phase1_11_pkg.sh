#!/usr/bin/env bash
set -e
echo "🐾 PantherLang Phase 1.11 — Package Manager Bootstrap"
echo "Root: $(pwd)"

mkdir -p language/pkg scripts docs packages

cat > language/pkg/panther_pkg.py <<'EOF'
#!/usr/bin/env python3
import argparse
parser=argparse.ArgumentParser(prog="panther-pkg")
sub=parser.add_subparsers(dest="cmd")
for c in ["init","install","list","publish"]:
    sub.add_parser(c)
a=parser.parse_args()
if a.cmd=="init":
    print("Initialized panther.pkg")
elif a.cmd=="install":
    print("Package installation placeholder")
elif a.cmd=="list":
    print("Core packages:\npanther.core\npanther.math\npanther.ai")
elif a.cmd=="publish":
    print("Publish placeholder")
else:
    parser.print_help()
EOF
chmod +x language/pkg/panther_pkg.py

cat > docs/PACKAGE_MANAGER.md <<'EOF'
# Panther Package Manager
Future command:
panther pkg install
panther pkg publish
EOF

cat > scripts/verify_phase1_pkg.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
python3 language/pkg/panther_pkg.py list | grep -q panther.core
echo "✅ PantherLang Phase 1.11 package manager verification complete."
EOF
chmod +x scripts/verify_phase1_pkg.sh
bash scripts/verify_phase1_pkg.sh
echo "--------------------------------"
echo "✅ PantherLang Phase 1.11 Package Manager installed successfully."
echo "Run anytime: bash scripts/verify_phase1_pkg.sh"
echo "--------------------------------"
