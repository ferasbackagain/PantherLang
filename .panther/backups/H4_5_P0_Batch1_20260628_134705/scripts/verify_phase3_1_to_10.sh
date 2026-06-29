#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase3_1_to_10_runtime.py
echo "✅ PantherLang Phase 3.1–3.10 verification complete."
