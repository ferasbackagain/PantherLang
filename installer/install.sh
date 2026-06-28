#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sudo install -m 755 "$ROOT/panther" /usr/local/bin/Panther

echo "Panther installed successfully."
echo
echo "Try:"
echo "  Panther doctor"
echo "  Panther run examples/phase7_cli/cli_run_demo.panther"
