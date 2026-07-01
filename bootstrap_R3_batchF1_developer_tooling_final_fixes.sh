#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP="$ROOT/.panther/backups/R3_batchF1_tooling_final_fixes_$STAMP"
REPORT="$ROOT/.panther/reports/R3_batchF1_tooling_final_fixes_$STAMP"

mkdir -p "$BACKUP" "$REPORT"

echo "== R3 Batch F1: Developer Tooling Final Fixes =="

# Guard: must run from PantherLang repo root.
if [ ! -d "$ROOT/.panther/tools" ] || [ ! -f "$ROOT/.panther/tools/panther_cli.py" ]; then
  echo "ERROR: Run this script from PantherLang repository root."
  echo "Expected: .panther/tools/panther_cli.py"
  exit 1
fi

# Backup critical files.
for f in \
  panther \
  vscode-extension/package.json \
  vscode-extension/src/extension.js \
  vscode-extension/out/extension.js \
  vscode-extension/src/extension.ts \
  vscode-extension/out/debugFlow.js \
  vscode-extension/src/debugFlow.ts
do
  if [ -e "$ROOT/$f" ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp -a "$ROOT/$f" "$BACKUP/$f"
  fi
done

if [ -e "$HOME/.local/bin/panther" ]; then
  mkdir -p "$BACKUP/home_local_bin"
  cp -a "$HOME/.local/bin/panther" "$BACKUP/home_local_bin/panther"
fi

# 1) Restore repo-local panther launcher with version/help support and no recursion.
cat > "$ROOT/panther" <<'EOF'
#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$ROOT/vscode-extension/package.json"

if [ "${1:-}" = "version" ] || [ "${1:-}" = "--version" ] || [ "${1:-}" = "-v" ]; then
  if [ -f "$VERSION_FILE" ]; then
    VERSION="$(python3 - <<PY
import json
from pathlib import Path
p=Path("$VERSION_FILE")
print(json.loads(p.read_text(encoding="utf-8")).get("version","unknown"))
PY
)"
  else
    VERSION="unknown"
  fi
  echo "PantherLang Developer Edition CLI"
  echo "Version: $VERSION"
  exit 0
fi

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "help" ]; then
  cat <<'HELP'
PantherLang Developer Edition CLI

Usage:
  panther version
  panther doctor
  panther check <file.pan|file.panther>
  panther run <file.pan|file.panther>
  panther build <file.pan|file.panther> [--out <path>]
  panther new <console|api|web|ai> <project-name>

Notes:
  This development CLI is backed by .panther/tools/panther_cli.py.
HELP
  exit 0
fi

exec python3 "$ROOT/.panther/tools/panther_cli.py" "$@"
EOF
chmod +x "$ROOT/panther"

# 2) Install global wrapper that delegates to repo launcher without symlink recursion.
mkdir -p "$HOME/.local/bin"
rm -f "$HOME/.local/bin/panther"
cat > "$HOME/.local/bin/panther" <<EOF
#!/usr/bin/env bash
set -e
REPO="$ROOT"
exec "\$REPO/panther" "\$@"
EOF
chmod +x "$HOME/.local/bin/panther"

# 3) Ensure VS Code file icon theme exists and maps .pan/.panther files.
mkdir -p "$ROOT/vscode-extension/icons"
cat > "$ROOT/vscode-extension/icons/pantherlang-icons.json" <<'EOF'
{
  "iconDefinitions": {
    "_panther_file": {
      "iconPath": "../assets/pantherlang-icon.png"
    }
  },
  "fileExtensions": {
    "pan": "_panther_file",
    "panther": "_panther_file"
  },
  "fileNames": {
    "panther.toml": "_panther_file"
  }
}
EOF

# 4) Patch VS Code package.json safely.
python3 - <<'PY'
import json
from pathlib import Path

pkg_path = Path("vscode-extension/package.json")
data = json.loads(pkg_path.read_text(encoding="utf-8"))

# Keep existing identity stable; only ensure expected public metadata.
data["displayName"] = "PantherLang"
data.setdefault("name", "pantherlang-official")
data.setdefault("publisher", "pantherlang")
data.setdefault("version", "1.1.3")

activation = data.setdefault("activationEvents", [])
for event in [
    "onDebug",
    "onDebugResolve:panther",
    "onDebugInitialConfigurations",
    "onCommand:panther.debug.start",
]:
    if event not in activation:
        activation.append(event)

contrib = data.setdefault("contributes", {})

# Languages
languages = contrib.setdefault("languages", [])
if not any(x.get("id") == "panther" for x in languages):
    languages.append({
        "id": "panther",
        "aliases": ["PantherLang", "panther"],
        "extensions": [".pan", ".panther"],
        "configuration": "./language-configuration.json"
    })
else:
    for lang in languages:
        if lang.get("id") == "panther":
            exts = lang.setdefault("extensions", [])
            for ext in [".pan", ".panther"]:
                if ext not in exts:
                    exts.append(ext)

# Icon theme
icon_themes = contrib.setdefault("iconThemes", [])
theme_id = "pantherlang-icons"
if not any(t.get("id") == theme_id for t in icon_themes):
    icon_themes.append({
        "id": theme_id,
        "label": "PantherLang Icons",
        "path": "./icons/pantherlang-icons.json"
    })

# Command
commands = contrib.setdefault("commands", [])
if not any(c.get("command") == "panther.debug.start" for c in commands):
    commands.append({
        "command": "panther.debug.start",
        "title": "PantherLang: F5 Debug Current File",
        "category": "PantherLang"
    })

# Debugger contribution
debuggers = contrib.setdefault("debuggers", [])
if not any(d.get("type") == "panther" for d in debuggers):
    debuggers.append({
        "type": "panther",
        "label": "PantherLang Debug",
        "program": "./out/extension.js",
        "runtime": "node",
        "configurationAttributes": {
            "launch": {
                "required": ["program"],
                "properties": {
                    "program": {
                        "type": "string",
                        "description": "PantherLang program to debug."
                    }
                }
            }
        },
        "initialConfigurations": [
            {
                "name": "PantherLang: F5 Debug Current File",
                "type": "panther",
                "request": "launch",
                "program": "${file}",
                "preLaunchTask": "PantherLang: Check"
            }
        ]
    })

pkg_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY

# 5) Ensure src/out extension JS remain byte-identical when tests require it.
if [ -f "$ROOT/vscode-extension/out/extension.js" ]; then
  cp "$ROOT/vscode-extension/out/extension.js" "$ROOT/vscode-extension/src/extension.js"
fi

# 6) Sanity checks.
echo "== Sanity checks =="
timeout 10s "$ROOT/panther" version
timeout 10s "$HOME/.local/bin/panther" version
timeout 10s "$HOME/.local/bin/panther" check "$ROOT/examples/hello.pan"

# Verify icon contribution exists.
python3 - <<'PY'
import json
from pathlib import Path
pkg=json.loads(Path("vscode-extension/package.json").read_text(encoding="utf-8"))
themes=pkg.get("contributes",{}).get("iconThemes",[])
assert any(t.get("id")=="pantherlang-icons" for t in themes), "missing PantherLang Icons theme"
icons=json.loads(Path("vscode-extension/icons/pantherlang-icons.json").read_text(encoding="utf-8"))
assert icons["fileExtensions"]["pan"] == "_panther_file"
assert icons["fileExtensions"]["panther"] == "_panther_file"
print("VS Code file icon theme contract: OK")
PY

cat > "$REPORT/REPORT.md" <<EOF
# R3 Batch F1 — Developer Tooling Final Fixes

Applied:
- Restored repo-local ./panther launcher without recursion.
- Added panther version/help wrapper behavior.
- Installed global ~/.local/bin/panther wrapper.
- Added VS Code PantherLang file icon theme for .pan and .panther.
- Ensured VS Code package metadata/contributions are stable.

Validation:
- panther version
- panther check examples/hello.pan
- VS Code icon theme contract check

Next:
- Run full regression:
  python3 -m pytest -q
- Rebuild VSIX only after regression is clean.
EOF

echo "R3 Batch F1 Developer Tooling Final Fixes applied."
echo "Backup: $BACKUP"
echo "Report: $REPORT"
echo "Next run:"
echo "python3 -m pytest -q"
