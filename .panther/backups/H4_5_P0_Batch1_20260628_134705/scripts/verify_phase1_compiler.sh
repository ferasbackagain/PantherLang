#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_compiler.py
echo "✅ PantherLang Phase 1.7 compiler verification complete."
