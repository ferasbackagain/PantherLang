#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tools/panther-regression/panther_regression.py --mode fast --timeout 180
