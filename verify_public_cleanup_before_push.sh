#!/usr/bin/env bash
set -euo pipefail
echo "== PantherLang public cleanup verification =="

echo "[1/7] Git status"
git status --short

echo "[2/7] Diff summary"
git diff --stat || true

echo "[3/7] Required trees"
for p in compiler runtime cli tests docs academy examples vscode-extension website debug_adapter debug_adapter_rebuilt; do
  test -e "$p" || { echo "MISSING $p"; exit 1; }
  echo "KEEP $p"
done

echo "[4/7] Version"
panther version

echo "[5/7] Doctor"
panther doctor

echo "[6/7] Full regression"
python -m pytest tests/ -q

echo "[7/7] VS Code extension inventory"
test -d vscode-extension
find vscode-extension -maxdepth 2 -type f | head -50

echo "Verification completed. Review git diff before commit/push."
