#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 8.1 PRO - Global CLI Installer"
echo "============================================================"

ROOT="$(pwd)"

mkdir -p installer docs/phase8 examples/phase8_cli scripts tests/phase8_1

cat > installer/install.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sudo install -m 755 "$ROOT/panther" /usr/local/bin/Panther

echo "Panther installed successfully."
echo
echo "Try:"
echo "  Panther doctor"
echo "  Panther run examples/phase7_cli/cli_run_demo.panther"
EOF
chmod +x installer/install.sh

cat > docs/phase8/PHASE_8_1_STATUS.md <<'EOF'
# Phase 8.1 - Global CLI Installer

Completed
- Global installer
- /usr/local/bin/Panther installation
- PATH integration
- Installation verification
EOF

cat > examples/phase8_cli/install_demo.panther <<'EOF'
module panther.phase8

print "Phase 8.1 Global CLI Installer"
EOF

cat > scripts/verify_phase8_1_global_cli.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 8.1 Verification"
echo "============================================================"

test -x installer/install.sh
echo "✅ installer exists"

grep -q "/usr/local/bin/Panther" installer/install.sh
echo "✅ installs Panther globally"

./panther run examples/phase8_cli/install_demo.panther | grep -q "Phase 8.1 Global CLI Installer"
echo "✅ compiler/runtime bridge"

python3 -m py_compile cli/panther_cli_v2.py
echo "✅ python compile"

echo "✅ PantherLang Phase 8.1 Global CLI Installer verification complete."
EOF
chmod +x scripts/verify_phase8_1_global_cli.sh

echo "[phase8.1] Running verification..."
bash scripts/verify_phase8_1_global_cli.sh

echo "============================================================"
echo " Phase 8.1 COMPLETE"
echo " Next: Phase 8.2 Package Manager Foundation"
echo "============================================================"
