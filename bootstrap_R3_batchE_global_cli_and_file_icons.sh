#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
BATCH="R3_batchE_global_cli_and_file_icons"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.panther/backups/${BATCH}_${STAMP}"
REPORT_DIR="$ROOT/.panther/reports/${BATCH}_${STAMP}"
mkdir -p "$BACKUP_DIR" "$REPORT_DIR"

fail() { echo "ERROR: $*" >&2; exit 1; }
[ -f "$ROOT/panther" ] || fail "Run this script from PantherLang repository root. Missing ./panther"
[ -d "$ROOT/vscode-extension" ] || fail "Missing vscode-extension directory"

mkdir -p "$HOME/.local/bin"
if [ -e "$HOME/.local/bin/panther" ] || [ -L "$HOME/.local/bin/panther" ]; then
  cp -a "$HOME/.local/bin/panther" "$BACKUP_DIR/panther.local.bin.backup" 2>/dev/null || true
fi

cat > "$HOME/.local/bin/panther" <<EOF_WRAPPER
#!/usr/bin/env bash
set -e
REPO="$ROOT"
exec "\$REPO/panther" "\$@"
EOF_WRAPPER
chmod +x "$HOME/.local/bin/panther"

EXT="$ROOT/vscode-extension"
mkdir -p "$EXT/icons"

# Use existing PNG as icon source. VS Code product icon/file icon themes can point to PNG.
if [ -f "$EXT/assets/pantherlang-icon.png" ]; then
  cp "$EXT/assets/pantherlang-icon.png" "$EXT/icons/pantherlang-icon.png"
else
  cat > "$EXT/icons/pantherlang-icon.svg" <<'EOF_SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <rect width="128" height="128" rx="24" fill="#05070d"/>
  <path d="M64 14L106 39v50L64 114 22 89V39z" fill="#0a84ff" opacity="0.18"/>
  <path d="M31 83c16-38 30-54 66-56-20 14-26 32-24 58-11-13-23-16-42-2z" fill="#0a84ff"/>
  <text x="64" y="104" text-anchor="middle" font-size="18" font-family="Arial" fill="#ffffff">PAN</text>
</svg>
EOF_SVG
fi

cat > "$EXT/icons/pantherlang-icon-theme.json" <<'EOF_THEME'
{
  "iconDefinitions": {
    "pantherlang-file": {
      "iconPath": "./pantherlang-icon.png"
    }
  },
  "fileExtensions": {
    "pan": "pantherlang-file",
    "panther": "pantherlang-file"
  },
  "languageIds": {
    "panther": "pantherlang-file",
    "pantherlang": "pantherlang-file"
  }
}
EOF_THEME

python3 - <<'PY'
import json
from pathlib import Path
pkg = Path('vscode-extension/package.json')
data = json.loads(pkg.read_text(encoding='utf-8'))
contrib = data.setdefault('contributes', {})
icon_themes = contrib.setdefault('iconThemes', [])
entry = {
    "id": "pantherlang-icons",
    "label": "PantherLang Icons",
    "path": "./icons/pantherlang-icon-theme.json"
}
# Replace same id, preserve others.
icon_themes = [x for x in icon_themes if x.get('id') != entry['id']]
icon_themes.append(entry)
contrib['iconThemes'] = icon_themes
# Keep identity stable; only set known safe metadata if missing.
data.setdefault('publisher', 'pantherlang')
data.setdefault('name', 'pantherlang-official')
# Ensure display name is stable for Marketplace updates.
data['displayName'] = 'PantherLang'
pkg.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding='utf-8')
PY

# Ensure icon files are included by npm/vsce package if package.json has files list.
python3 - <<'PY'
import json
from pathlib import Path
pkg = Path('vscode-extension/package.json')
data = json.loads(pkg.read_text(encoding='utf-8'))
files = data.get('files')
if isinstance(files, list):
    for item in ['icons/**', 'assets/**']:
        if item not in files:
            files.append(item)
    data['files'] = files
    pkg.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding='utf-8')
PY

cat > "$REPORT_DIR/ENGINEERING_REPORT.md" <<EOF_REPORT
# $BATCH

Applied at: $STAMP

## Changes
- Replaced global \`~/.local/bin/panther\` with a stable wrapper pointing to this repository root.
- Added VS Code file icon theme for \`.pan\` and \`.panther\` files.
- Added icon theme contribution to \`vscode-extension/package.json\`.

## Verification commands
\`\`\`bash
hash -r
which panther
panther version
panther check examples/hello.pan
python3 -m pytest -q
cd vscode-extension && npx vsce package
\`\`\`
EOF_REPORT

cat > "$ROOT/BATCH_E_MANIFEST.json" <<EOF_JSON
{
  "batch": "$BATCH",
  "timestamp": "$STAMP",
  "changes": [
    "global panther wrapper",
    "vscode file icon theme",
    "package.json iconThemes contribution"
  ],
  "backup": "$BACKUP_DIR",
  "report": "$REPORT_DIR"
}
EOF_JSON

echo "R3 Batch E Global CLI + File Icons applied."
echo "Backup: $BACKUP_DIR"
echo "Report: $REPORT_DIR"
echo "Now run: hash -r && panther version && panther check examples/hello.pan"
echo "Then rebuild VSIX from vscode-extension."
