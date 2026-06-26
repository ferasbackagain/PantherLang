#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase2_2_to_10.py
echo "✅ PantherLang Phase 2.2–2.10 full verification complete."
