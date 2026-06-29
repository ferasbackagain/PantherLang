#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_ir.py
echo "✅ PantherLang Phase 1.5 IR verification complete."
