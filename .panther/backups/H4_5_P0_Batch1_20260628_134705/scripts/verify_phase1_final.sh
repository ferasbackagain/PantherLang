#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_16_runtime.py
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_17_repl.py
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_18_registry.py
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_19_ide.py

test -f docs/PHASE_1_COMPLETE.md
test -f releases/PANTHERLANG_DEVELOPER_PREVIEW_v0_5.md

echo "✅ PantherLang Phase 1.16–1.20 final verification complete."
