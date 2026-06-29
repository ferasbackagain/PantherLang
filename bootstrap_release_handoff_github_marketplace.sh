#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang"
echo " GitHub Safe Publish + VS Code Marketplace Readiness"
echo " Non-destructive release handoff"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
VERSION="v0.9.10-debug-adapter-official"
REPORT_DIR="$ROOT/reports/release_handoff"
STATUS_DIR="$ROOT/.panther/release_handoff"
BACKUP_DIR="$ROOT/.panther/backups/release_handoff_${STAMP}"

mkdir -p "$REPORT_DIR" "$STATUS_DIR" "$BACKUP_DIR"

fail(){ echo "[RELEASE-HANDOFF][ERROR] $1" >&2; exit 1; }
warn(){ echo "[RELEASE-HANDOFF][WARN] $1" >&2; }

echo "[1/12] Pre-flight project gates..."
[ -d ".git" ] || fail "This is not a Git repository."
[ -f ".panther/p3_batch10_official_release/status_batch10_final.json" ] || fail "P-3 Batch 10 final status missing."
[ -d "debug_adapter" ] || fail "debug_adapter missing."
[ -d "vscode-extension" ] || warn "vscode-extension folder missing; Marketplace packaging will be skipped."

echo "[2/12] Safety snapshot..."
cp -a .panther/p3_batch10_official_release "$BACKUP_DIR/p3_batch10_official_release"
cp -a debug_adapter "$BACKUP_DIR/debug_adapter"
[ -d vscode-extension ] && cp -a vscode-extension "$BACKUP_DIR/vscode-extension" || true

echo "[3/12] Compile + regression..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
if [ -d tests/P3_atomic_replacement ]; then
  python3 -m pytest tests/P3_atomic_replacement -q
fi

echo "[4/12] Inspecting Git status..."
git status --short > "$STATUS_DIR/git_status_before_${STAMP}.txt"

if git status --short | grep -E '^( D|D |RD|R |AD|MD)' >/dev/null 2>&1; then
  echo "Detected deleted/removed files in Git status:"
  git status --short | grep -E '^( D|D |RD|R |AD|MD)' || true
  fail "Refusing to stage deletions. Restore or review deleted files first."
fi

echo "[5/12] Creating release handoff manifest..."
python3 <<'PY'
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
status_dir = root / ".panther" / "release_handoff"

def hash_tree(base: Path):
    rows=[]
    if not base.exists():
        return rows
    for p in sorted(base.rglob("*")):
        if p.is_file() and ".git/" not in p.as_posix():
            rows.append({
                "path": p.relative_to(root).as_posix(),
                "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
                "size": p.stat().st_size,
            })
    return rows

manifest = {
    "ok": True,
    "name": "GitHub Safe Publish + VS Code Marketplace Readiness",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "v0.9.10-debug-adapter-official",
    "non_destructive_policy": {
        "no_git_rm": True,
        "no_stage_deletions": True,
        "git_add_ignore_removal": True
    },
    "debug_adapter_files": hash_tree(root / "debug_adapter"),
    "official_release_files": hash_tree(root / ".panther" / "p3_batch10_official_release"),
    "vscode_extension_files": hash_tree(root / "vscode-extension"),
}
(status_dir / "release_handoff_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ manifest written")
PY

echo "[6/12] Non-destructive Git staging..."
# IMPORTANT:
# --ignore-removal stages new/modified files but does NOT stage deletions.
git add --ignore-removal .

# Extra safety: unstage any deletion if somehow staged.
if git diff --cached --name-status | grep -E '^D' >/dev/null 2>&1; then
  git diff --cached --name-status | grep -E '^D' | awk '{print $2}' | while read -r f; do
    git restore --staged "$f" || true
  done
fi

if git diff --cached --name-status | grep -E '^D' >/dev/null 2>&1; then
  fail "Deletion is still staged. Aborting."
fi

echo "[7/12] Writing staged summary..."
git diff --cached --name-status > "$STATUS_DIR/git_staged_${STAMP}.txt"
cat "$STATUS_DIR/git_staged_${STAMP}.txt" | tail -80

if [ ! -s "$STATUS_DIR/git_staged_${STAMP}.txt" ]; then
  warn "No staged changes found. Commit will be skipped."
else
  echo "[8/12] Creating Git commit..."
  git commit -m "release: PantherLang debug adapter official ${VERSION}" || warn "Commit failed or nothing to commit."
fi

echo "[9/12] Creating/refreshing annotated tag..."
if git rev-parse "$VERSION" >/dev/null 2>&1; then
  warn "Tag $VERSION already exists. Not overwriting."
else
  git tag -a "$VERSION" -m "PantherLang Debug Adapter Official Release ${VERSION}"
fi

echo "[10/12] VS Code extension packaging readiness..."
if [ -d "vscode-extension" ]; then
  (
    cd vscode-extension

    [ -f package.json ] || fail "vscode-extension/package.json missing."

    node -e "JSON.parse(require('fs').readFileSync('package.json','utf8')); console.log('package.json OK')"

    if [ ! -f README.md ]; then
      cat > README.md <<'EOF'
# PantherLang

Official PantherLang VS Code extension.

## Features

- PantherLang language support
- PantherLang commands
- Debug Adapter integration
- Development workflow support

## Requirements

PantherLang CLI must be installed and available on PATH.

## Release

This VSIX is prepared from the PantherLang official debug adapter release.
EOF
    fi

    [ -f CHANGELOG.md ] || cat > CHANGELOG.md <<'EOF'
# Changelog

## 0.9.10

- Official Debug Adapter release.
- Canonical Debug Adapter rebuild.
- Production certification.
EOF

    [ -f LICENSE ] || cat > LICENSE <<'EOF'
Copyright (c) Feras Khatib.

All rights reserved unless a separate license is provided by the project owner.
EOF

    if ! command -v vsce >/dev/null 2>&1; then
      echo "[INFO] Installing @vscode/vsce globally. This may require npm permissions."
      npm install -g @vscode/vsce
    fi

    vsce package
  )
else
  warn "vscode-extension not found, skipping VSIX packaging."
fi

echo "[11/12] Optional push/publish controls..."
cat > "$REPORT_DIR/RELEASE_HANDOFF_NEXT_COMMANDS.md" <<EOF
# Release handoff next commands

## Push to GitHub

This script staged changes using \`git add --ignore-removal .\`, so deletions were not staged.

To push the current branch and tags:

\`\`\`bash
git push origin HEAD
git push origin $VERSION
\`\`\`

If your branch is main:

\`\`\`bash
git push origin main
git push origin $VERSION
\`\`\`

## Publish VS Code Marketplace

Inside \`vscode-extension/\`:

\`\`\`bash
cd vscode-extension
vsce package
vsce login <publisher-id>
vsce publish
\`\`\`

Or with token:

\`\`\`bash
cd vscode-extension
VSCE_PAT=<your_marketplace_manage_token> vsce publish
\`\`\`

## Install VSIX locally

\`\`\`bash
code --install-extension vscode-extension/*.vsix
\`\`\`
EOF

if [ "${PUSH:-0}" = "1" ]; then
  echo "[12/12] PUSH=1 enabled: pushing branch and tag..."
  CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  git push origin "$CURRENT_BRANCH"
  git push origin "$VERSION"
else
  echo "[12/12] PUSH not enabled. No remote push performed."
fi

if [ "${PUBLISH_MARKETPLACE:-0}" = "1" ]; then
  [ -n "${VSCE_PAT:-}" ] || fail "PUBLISH_MARKETPLACE=1 requires VSCE_PAT."
  [ -d "vscode-extension" ] || fail "vscode-extension missing."
  (
    cd vscode-extension
    VSCE_PAT="$VSCE_PAT" vsce publish
  )
else
  echo "Marketplace publish not enabled. Set PUBLISH_MARKETPLACE=1 VSCE_PAT=... to publish."
fi

echo "============================================================"
echo "✅ RELEASE HANDOFF COMPLETE"
echo "GitHub: staged/committed/tagged without staging deletions"
echo "Marketplace: VSIX readiness completed if vscode-extension exists"
echo "Report: reports/release_handoff/RELEASE_HANDOFF_NEXT_COMMANDS.md"
echo "============================================================"
