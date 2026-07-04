#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
panther run examples/stdlib_s1_s6_contract/main.pan
