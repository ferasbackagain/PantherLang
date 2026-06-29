#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/../language"
export PYTHONPATH="$PWD:$PYTHONPATH"
python3 tests/test_v0_5.py
python3 panther.py doctor
python3 panther.py check examples/store.panther
python3 panther.py semantic examples/store.panther >/tmp/panther_semantic.json
python3 panther.py ir examples/store.panther >/tmp/panther_ir.json
echo "✅ PantherLang v0.5 test suite passed."
