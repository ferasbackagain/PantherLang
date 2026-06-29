#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT/vscode-extension"

[ -n "${VSCE_PAT:-}" ] || {
  echo "[PUBLISH][ERROR] VSCE_PAT missing."
  echo "Usage:"
  echo "  VSCE_PAT=<token> bash .panther/R2_marketplace_professionalization/publish_from_vsix_gate.sh"
  exit 1
}

npx --yes @vscode/vsce publish --packagePath "../releases/vscode_marketplace/pantherlang-1.0.0.vsix"
