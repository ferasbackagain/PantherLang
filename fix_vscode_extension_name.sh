#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo "PantherLang VS Code Extension Name Fix"
echo "========================================"

PACKAGE_JSON=$(find . -type f -name package.json | head -n 1)

if [ -z "$PACKAGE_JSON" ]; then
    echo "ERROR: package.json not found."
    exit 1
fi

echo "Found: $PACKAGE_JSON"

cp "$PACKAGE_JSON" "${PACKAGE_JSON}.bak"

python3 <<PY
import json
from pathlib import Path

p = Path("$PACKAGE_JSON")
data = json.loads(p.read_text(encoding="utf-8"))

old = data.get("name","")

if old == "pantherlang":
    data["name"] = "pantherlang-official"
    print(f"Changed name: {old} -> {data['name']}")
else:
    print(f"Current name is '{old}', leaving unchanged.")

p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY

echo
echo "Current values:"
grep -E '"name"|"displayName"|"publisher"|"version"' "$PACKAGE_JSON"

echo
echo "Done."
echo "Backup:"
echo "${PACKAGE_JSON}.bak"
