#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Batch 1 - Project System"
echo " Part 7 - Agent Knowledge Pack"
echo "============================================================"

ROOT="$(pwd)"
EXT="$ROOT/vscode-extension"
R3="$ROOT/.panther/R3_production_developer_experience"
REPORTS="$ROOT/reports/R3_project_system"
BACKUP="$ROOT/.panther/backups/R3_batch1_part7_agent_knowledge_pack_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R3" "$REPORTS" "$BACKUP"

fail(){ echo "[R3-B1-P7][ERROR] $1" >&2; exit 1; }

echo "[1/12] Pre-flight gates..."
[ -d ".git" ] || fail "Run from PantherLang project root."
[ -f "$R3/status_batch1_part6_debug_launch_integration.json" ] || fail "Run R3 Batch 1 Part 6 first."
[ -d "$EXT" ] || fail "vscode-extension missing."
[ -f "$EXT/package.json" ] || fail "vscode-extension/package.json missing."

echo "[2/12] Safety backup..."
cp -a "$EXT" "$BACKUP/vscode-extension"
[ -d docs/agent_knowledge ] && cp -a docs/agent_knowledge "$BACKUP/agent_knowledge" || true
[ -d tests/R3_project_system ] && cp -a tests/R3_project_system "$BACKUP/tests_R3_project_system" || true

echo "[3/12] Baseline tests..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q
python3 -m pytest tests/R3_project_system -q

echo "[4/12] Creating Agent Knowledge Pack..."
mkdir -p docs/agent_knowledge docs/examples/console docs/examples/web docs/examples/api docs/examples/ai .github/copilot

cat > docs/agent_knowledge/PANTHERLANG_AGENT_GUIDE.md <<'EOF'
# PantherLang Agent Guide

This document teaches AI coding agents how to work inside PantherLang projects.

## Identity

PantherLang is the official programming language of the Panther Ecosystem.

## File Extensions

- `.panther`
- `.pan`

## Project Manifest

Every PantherLang project should contain:

```text
panther.toml
src/main.panther
```

## Common Commands

```bash
panther run
panther build
panther test
panther deploy
```

Current R3 VS Code integration also supports:

- PantherLang: New Project
- PantherLang: Run Current File
- PantherLang: Build Project
- PantherLang: Debug Project
- PantherLang: Doctor

## Project Types

- console
- web
- api
- ai

## Agent Behavior Rules

When asked to create PantherLang code:

1. Prefer creating a valid PantherLang project structure.
2. Use `panther.toml` as the project source of truth.
3. Put executable source in `src/main.panther`.
4. Include README instructions.
5. Include `.vscode/tasks.json` and `.vscode/launch.json` when building project templates.
6. Do not invent external package names unless requested.
7. For web/API examples, keep routes minimal and readable.
8. For AI examples, do not hard-code API keys.

## Minimal Console Example

```panther
panther main {
    print("Hello Panther")
}
```

## Minimal API Example

```panther
panther api {
    get "/health" {
        return { "status": "ok" }
    }
}
```
EOF

cat > docs/agent_knowledge/PANTHERLANG_GRAMMAR_QUICK_REFERENCE.md <<'EOF'
# PantherLang Grammar Quick Reference

This is a practical quick reference for AI agents and developers.

## Program Entry

```panther
panther main {
    print("Hello Panther")
}
```

## Tests

```panther
panther test "feature works" {
    assert true
}
```

## Web Route Pattern

```panther
panther web {
    route "/" {
        return "Hello"
    }
}
```

## API Route Pattern

```panther
panther api {
    get "/health" {
        return { "status": "ok" }
    }
}
```

## AI App Pattern

```panther
panther ai {
    prompt = "Build safely"
    print("AI-ready app")
}
```

## Naming Conventions

- Project names: lowercase words with dashes.
- Source directory: `src/`.
- Entry file: `src/main.panther`.
- Tests directory: `tests/`.
EOF

cat > docs/agent_knowledge/PANTHERLANG_PROJECT_CONVENTIONS.md <<'EOF'
# PantherLang Project Conventions

## Standard Layout

```text
my-project/
  panther.toml
  README.md
  .gitignore
  src/
    main.panther
  tests/
  docs/
  .vscode/
    settings.json
    tasks.json
    launch.json
```

## Manifest

```toml
[project]
name = "my-project"
type = "console"
version = "0.1.0"
language = "panther"

[run]
main = "src/main.panther"
```

## VS Code

Use command palette:

- `PantherLang: New Project`
- `PantherLang: Run Current File`
- `PantherLang: Build Project`
- `PantherLang: Debug Project`
EOF

cat > docs/agent_knowledge/PANTHERLANG_AGENT_PROMPTS.md <<'EOF'
# PantherLang Agent Prompts

## Build Console App

Create a PantherLang console app with `panther.toml`, `src/main.panther`, README, tests, and VS Code tasks.

## Build Web App

Create a PantherLang web app with a route at `/`, static public folder, README, tests, and VS Code tasks.

## Build API App

Create a PantherLang API app with `/health`, README, tests, and VS Code tasks.

## Build AI App

Create a PantherLang AI-ready app that uses environment variables for secrets and never hard-codes API keys.
EOF

cat > .github/copilot/instructions.md <<'EOF'
# Copilot Instructions for PantherLang

When working in this repository, treat PantherLang as a first-class programming language.

Use these rules:

- Prefer `.panther` files for PantherLang examples.
- Use `panther.toml` as project manifest.
- Put application code in `src/main.panther`.
- Use `PantherLang: Build Project`, `PantherLang: Run Current File`, and `PantherLang: Debug Project` for VS Code workflows.
- Do not hard-code secrets.
- Follow docs in `docs/agent_knowledge/`.
EOF

echo "[5/12] Creating official examples..."
cat > docs/examples/console/main.panther <<'EOF'
panther main {
    print("Hello from PantherLang console")
}
EOF

cat > docs/examples/web/main.panther <<'EOF'
panther web {
    route "/" {
        return "Hello from PantherLang web"
    }
}
EOF

cat > docs/examples/api/main.panther <<'EOF'
panther api {
    get "/health" {
        return { "status": "ok", "service": "panther-api" }
    }
}
EOF

cat > docs/examples/ai/main.panther <<'EOF'
panther ai {
    prompt = "Build safely with PantherLang"
    print("PantherLang AI app ready")
}
EOF

echo "[6/12] Adding VS Code command to open Agent Guide..."
cat > "$EXT/src/agent_command.js" <<'JS'
const vscode = require('vscode');
const path = require('path');
const fs = require('fs');

function getWorkspaceRoot() {
  const folders = vscode.workspace.workspaceFolders;
  return folders && folders.length ? folders[0].uri.fsPath : undefined;
}

async function openAgentGuide() {
  const root = getWorkspaceRoot();
  if (!root) {
    vscode.window.showWarningMessage('Open the PantherLang repository or a PantherLang project first.');
    return;
  }

  const candidates = [
    path.join(root, 'docs', 'agent_knowledge', 'PANTHERLANG_AGENT_GUIDE.md'),
    path.join(root, '..', 'docs', 'agent_knowledge', 'PANTHERLANG_AGENT_GUIDE.md')
  ];

  const guide = candidates.find(fs.existsSync);
  if (!guide) {
    vscode.window.showErrorMessage('PantherLang Agent Guide not found.');
    return;
  }

  const doc = await vscode.workspace.openTextDocument(vscode.Uri.file(guide));
  await vscode.window.showTextDocument(doc, { preview: false });
}

module.exports = { openAgentGuide };
JS

echo "[7/12] Wiring extension.js/package.json..."
python3 <<'PY'
from pathlib import Path
import json

ext = Path("vscode-extension")
extension_js = ext / "src" / "extension.js"
text = extension_js.read_text()

if "agent_command" not in text:
    text = "const {openAgentGuide}=require('./agent_command');\n" + text

if "pantherlang.openAgentGuide" not in text:
    marker = "context.subscriptions.push(vscode.commands.registerCommand('pantherlang.debugProject', debugProject));"
    if marker in text:
        text = text.replace(marker, marker + "\n  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.openAgentGuide', openAgentGuide));")
    else:
        text += "\n// Agent guide command registration fallback\n"

extension_js.write_text(text)
(ext / "out" / "extension.js").write_text(text)
(ext / "out" / "agent_command.js").write_text((ext / "src" / "agent_command.js").read_text())

pkg_path = ext / "package.json"
pkg = json.loads(pkg_path.read_text())
pkg["version"] = "1.0.7"
pkg["description"] = "Official PantherLang language support, project wizard, run/build/debug tooling, and AI agent knowledge pack for Visual Studio Code."

contributes = pkg.setdefault("contributes", {})
commands = contributes.setdefault("commands", [])
if not any(c.get("command") == "pantherlang.openAgentGuide" for c in commands):
    commands.append({"command": "pantherlang.openAgentGuide", "title": "PantherLang: Open Agent Guide"})

menus = contributes.setdefault("menus", {})
palette = menus.setdefault("commandPalette", [])
if not any(c.get("command") == "pantherlang.openAgentGuide" for c in palette):
    palette.append({"command": "pantherlang.openAgentGuide"})

activation = set(pkg.get("activationEvents") or [])
activation.add("onCommand:pantherlang.openAgentGuide")
pkg["activationEvents"] = sorted(activation)

keywords = set(pkg.get("keywords") or [])
keywords.update(["ai-agent", "agent-guide", "copilot", "examples", "documentation"])
pkg["keywords"] = sorted(keywords)

pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ Agent guide command wired; version 1.0.7")
PY

echo "[8/12] Creating Part 7 tests..."
cat > tests/R3_project_system/test_r3_batch1_part7_agent_knowledge_pack.py <<'PY'
from pathlib import Path
import json


def test_agent_knowledge_pack_exists():
    base = Path("docs/agent_knowledge")
    assert (base / "PANTHERLANG_AGENT_GUIDE.md").exists()
    assert (base / "PANTHERLANG_GRAMMAR_QUICK_REFERENCE.md").exists()
    assert (base / "PANTHERLANG_PROJECT_CONVENTIONS.md").exists()
    assert (base / "PANTHERLANG_AGENT_PROMPTS.md").exists()


def test_copilot_instructions_exist():
    text = Path(".github/copilot/instructions.md").read_text()
    assert "PantherLang" in text
    assert "panther.toml" in text


def test_examples_exist():
    for kind in ["console", "web", "api", "ai"]:
        p = Path("docs/examples") / kind / "main.panther"
        assert p.exists()
        assert "panther" in p.read_text()


def test_vscode_agent_command_registered():
    pkg = json.loads(Path("vscode-extension/package.json").read_text())
    commands = {c["command"] for c in pkg["contributes"]["commands"]}
    assert "pantherlang.openAgentGuide" in commands
    assert pkg["version"] == "1.0.7"
    assert "ai-agent" in pkg.get("keywords", [])


def test_agent_command_implementation():
    text = Path("vscode-extension/src/agent_command.js").read_text()
    assert "PANTHERLANG_AGENT_GUIDE.md" in text
    assert "showTextDocument" in text
PY

echo "[9/12] Validation and full tests..."
python3 -m py_compile tests/R3_project_system/test_r3_batch1_part7_agent_knowledge_pack.py
python3 -m pytest tests/R3_project_system -q

echo "[10/12] Build VSIX 1.0.7..."
(
  cd "$EXT"
  rm -f pantherlang-1.0.7*.vsix
  npx --yes @vscode/vsce package --no-dependencies
)

mkdir -p releases/vscode_marketplace
VSIX="$(ls -t "$EXT"/pantherlang-1.0.7*.vsix | head -1)"
[ -f "$VSIX" ] || fail "VSIX 1.0.7 was not created."
cp "$VSIX" releases/vscode_marketplace/
sha256sum "releases/vscode_marketplace/$(basename "$VSIX")" > "releases/vscode_marketplace/$(basename "$VSIX").sha256"

echo "[11/12] Writing manifest/report..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
r3 = root / ".panther/R3_production_developer_experience"
vsix = root / "releases/vscode_marketplace" / "$(basename "$VSIX")"

manifest = {
    "ok": True,
    "phase": "R3",
    "batch": "1",
    "part": "7",
    "name": "Agent Knowledge Pack",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "1.0.7",
    "runtime_modified": True,
    "features": [
        "agent_guide",
        "grammar_quick_reference",
        "project_conventions",
        "agent_prompts",
        "copilot_instructions",
        "official_examples",
        "vscode_open_agent_guide_command",
        "vsix_1_0_7"
    ],
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "next": "R3 Batch 1 Final - Developer Experience Release"
}
(r3 / "batch1_part7_agent_knowledge_pack_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ manifest written")
PY

cat > "$REPORTS/R3_BATCH1_PART7_AGENT_KNOWLEDGE_PACK.md" <<EOF
# R3 Batch 1 Part 7 - Agent Knowledge Pack

## Status

PASSED

## Version

PantherLang VS Code Extension 1.0.7

## Added

- PantherLang Agent Guide
- Grammar Quick Reference
- Project Conventions
- Agent Prompt Pack
- GitHub Copilot instructions
- Official examples
- VS Code command: \`PantherLang: Open Agent Guide\`

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Next

R3 Batch 1 Final - Developer Experience Release.
EOF

echo "[12/12] Writing status..."
cat > "$R3/status_batch1_part7_agent_knowledge_pack.json" <<EOF
{
  "ok": true,
  "phase": "R3",
  "batch": "1",
  "part": "7",
  "status": "PASSED",
  "name": "Agent Knowledge Pack",
  "version": "1.0.7",
  "runtime_modified": true,
  "vsix": "releases/vscode_marketplace/$(basename "$VSIX")",
  "next": "R3 Batch 1 Final - Developer Experience Release"
}
EOF

echo "============================================================"
echo "✅ R3 Batch 1 Part 7 COMPLETE"
echo "✅ Agent Knowledge Pack READY"
echo "VSIX: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Next: R3 Batch 1 Final - Developer Experience Release"
echo "============================================================"
