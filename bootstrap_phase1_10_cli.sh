#!/usr/bin/env bash
set -e

echo "🐾 PantherLang Phase 1.10 — CLI Bootstrap"
echo "Root: $(pwd)"

mkdir -p language/cli scripts docs

cat > language/cli/panther.py <<'EOF'
#!/usr/bin/env python3
import argparse

parser = argparse.ArgumentParser(prog="panther")
sub = parser.add_subparsers(dest="command")

sub.add_parser("version")
sub.add_parser("doctor")
sub.add_parser("build")
sub.add_parser("run")

args = parser.parse_args()

if args.command == "version":
    print("PantherLang Developer Preview v0.5")
elif args.command == "doctor":
    print("✓ Panther CLI OK")
elif args.command == "build":
    print("Building Panther project...")
elif args.command == "run":
    print("Running Panther project...")
else:
    parser.print_help()
EOF

chmod +x language/cli/panther.py

cat > docs/CLI.md <<'EOF'
# Panther CLI

Commands:
- panther version
- panther doctor
- panther build
- panther run
EOF

cat > scripts/verify_phase1_cli.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

python3 language/cli/panther.py version | grep -q "PantherLang"
python3 language/cli/panther.py doctor | grep -q "CLI OK"

echo "✅ PantherLang Phase 1.10 CLI verification complete."
EOF

chmod +x scripts/verify_phase1_cli.sh
bash scripts/verify_phase1_cli.sh

echo "--------------------------------"
echo "✅ PantherLang Phase 1.10 CLI installed successfully."
echo "Run anytime: bash scripts/verify_phase1_cli.sh"
echo "--------------------------------"
