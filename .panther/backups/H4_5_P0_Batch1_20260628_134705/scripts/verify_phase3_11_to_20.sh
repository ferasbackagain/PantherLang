#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase3_11_to_20_runtime_packaging.py
test -f docs/PHASE_3_COMPLETE.md
test -f releases/PANTHER_RUNTIME_PHASE3_MANIFEST.md
echo "✅ PantherLang Phase 3.11–3.20 verification complete."
