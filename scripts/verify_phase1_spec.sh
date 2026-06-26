#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

test -f architecture/specification/PANTHER_LANGUAGE_SPECIFICATION_v1_8.md
test -f architecture/specification/KEYWORDS.md
test -f architecture/specification/SYNTAX_GUIDE.md
test -f language/examples/phase1_8_official_example.panther
test -f docs/PHASE_1_PLAN.md

grep -q "PantherLang is an independent" architecture/specification/PANTHER_LANGUAGE_SPECIFICATION_v1_8.md
grep -q "agent InventoryAI" language/examples/phase1_8_official_example.panther

echo "✅ PantherLang Phase 1.8 specification verification complete."
