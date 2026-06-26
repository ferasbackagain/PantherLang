#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase2_1_source_pipeline.py
echo "✅ PantherLang Phase 2.1 source pipeline verification complete."
