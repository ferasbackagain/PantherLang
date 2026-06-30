#!/usr/bin/env bash
set -euo pipefail

echo "Finding VS Code extension package.json..."

PKG=$(find . -type f -name package.json \
  -not -path "*/node_modules/*" \
  -exec grep -l '"engines".*"vscode"\|"vscode"' {} \; | head -n 1)

if [ -z "${PKG:-}" ]; then
  echo "ERROR: VS Code extension package.json not found."
  echo "Run: find . -name package.json"
  exit 1
fi

EXT_DIR="$(dirname "$PKG")"
echo "Extension dir: $EXT_DIR"

cd "$EXT_DIR"

cp package.json "package.json.bak.$(date +%Y%m%d_%H%M%S)"

python3 <<'PY'
import json
from pathlib import Path

p = Path("package.json")
data = json.loads(p.read_text(encoding="utf-8"))

if data.get("name") == "pantherlang":
    data["name"] = "pantherlang-official"

p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

print("name:", data.get("name"))
print("displayName:", data.get("displayName"))
print("publisher:", data.get("publisher"))
print("version:", data.get("version"))
PY

echo "Packaging..."
vsce package

echo
echo "Done. VSIX files:"
ls -lh *.vsix
