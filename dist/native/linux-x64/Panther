#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PANTHER_HOME="$(cd "$SCRIPT_DIR/../../.." && pwd)"
exec "$PANTHER_HOME/panther" "$@"
