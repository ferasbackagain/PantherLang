#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
python3 language/pkg/panther_pkg.py list | grep -q panther.core
echo "✅ PantherLang Phase 1.11 package manager verification complete."
