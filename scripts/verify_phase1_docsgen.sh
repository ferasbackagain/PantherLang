#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_docsgen.py
test -f docs/generated/PANTHERLANG_GENERATED_DOCS.md
echo "✅ PantherLang Phase 1.13 documentation generator verification complete."
