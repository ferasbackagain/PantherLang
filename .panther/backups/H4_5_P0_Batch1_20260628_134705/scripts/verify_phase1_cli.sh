#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

python3 language/cli/panther.py version | grep -q "PantherLang"
python3 language/cli/panther.py doctor | grep -q "CLI OK"

echo "✅ PantherLang Phase 1.10 CLI verification complete."
