#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)/vscode-extension"

if [ -z "${VSCE_PAT:-}" ]; then
  echo "[PUBLISH-GATE][ERROR] VSCE_PAT is required for non-interactive publish."
  echo "Run:"
  echo "  VSCE_PAT=<token> npx --yes @vscode/vsce publish"
  exit 1
fi

npx --yes @vscode/vsce publish
