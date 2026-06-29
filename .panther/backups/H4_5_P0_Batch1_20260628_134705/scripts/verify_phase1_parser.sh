#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_parser.py
echo "✅ PantherLang Phase 1.3 parser verification complete."
