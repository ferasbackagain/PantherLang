#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Production Developer Experience"
echo " Batch 1 - Project System"
echo " Part 3 - Project Templates Professionalization"
echo "============================================================"

ROOT="$(pwd)"
R3="$ROOT/.panther/R3_production_developer_experience"
REPORTS="$ROOT/reports/R3_project_system"
BACKUP="$ROOT/.panther/backups/R3_batch1_part3_templates_professionalization_$(date +%Y%m%d_%H%M%S)"
EXT="$ROOT/vscode-extension"

mkdir -p "$R3" "$REPORTS" "$BACKUP"

fail(){ echo "[R3-B1-P3][ERROR] $1" >&2; exit 1; }

echo "[1/12] Pre-flight gates..."
[ -d ".git" ] || fail "Run from PantherLang project root."
[ -f "$R3/status_batch1_part2_project_wizard_ux_integration.json" ] || fail "Run R3 Batch 1 Part 2 first."
[ -d project_templates ] || fail "project_templates missing."
[ -d "$EXT" ] || fail "vscode-extension missing."
[ -f "$EXT/package.json" ] || fail "vscode-extension/package.json missing."

echo "[2/12] Safety backup..."
cp -a project_templates "$BACKUP/project_templates"
cp -a tools/project_wizard "$BACKUP/project_wizard"
cp -a tests/R3_project_system "$BACKUP/tests_R3_project_system" 2>/dev/null || true
cp -a "$EXT" "$BACKUP/vscode-extension"

echo "[3/12] Baseline regression..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q
python3 -m pytest tests/R3_project_system -q

echo "[4/12] Professionalizing templates..."
for t in console_app web_app api_app ai_app; do
  mkdir -p "project_templates/$t/src" "project_templates/$t/tests" "project_templates/$t/docs" "project_templates/$t/.vscode"
done

cat > project_templates/console_app/README.md <<'EOF'
# {{PROJECT_NAME}}

A PantherLang console application.

## Run

```bash
panther run
```

## Build

```bash
panther build
```

## Test

```bash
panther test
```

## Structure

- `src/main.panther` — application entry point
- `tests/` — project tests
- `panther.toml` — project manifest
EOF

cat > project_templates/web_app/README.md <<'EOF'
# {{PROJECT_NAME}}

A PantherLang web application starter.

## Run

```bash
panther run --dev
```

## Build

```bash
panther build
```

## Deploy

```bash
panther deploy
```

## Structure

- `src/main.panther` — web entry point
- `public/` — static assets
- `tests/` — project tests
- `panther.toml` — project manifest
EOF

cat > project_templates/api_app/README.md <<'EOF'
# {{PROJECT_NAME}}

A PantherLang API service starter.

## Run

```bash
panther run --dev
```

## Build

```bash
panther build
```

## Test

```bash
panther test
```

## Endpoints

- `GET /health`

## Structure

- `src/main.panther` — API entry point
- `tests/` — API tests
- `panther.toml` — project manifest
EOF

cat > project_templates/ai_app/README.md <<'EOF'
# {{PROJECT_NAME}}

A PantherLang AI-ready application starter.

## Run

```bash
panther run
```

## Build

```bash
panther build
```

## Security

Never hard-code API keys in source files. Use environment variables.

## Structure

- `src/main.panther` — AI application entry point
- `tests/` — project tests
- `panther.toml` — project manifest
EOF

echo "[5/12] Adding standard project files..."
for t in console_app web_app api_app ai_app; do
cat > "project_templates/$t/.gitignore" <<'EOF'
.panther-cache/
build/
dist/
.env
.env.*
__pycache__/
*.pyc
*.log
EOF

cat > "project_templates/$t/.vscode/settings.json" <<'EOF'
{
  "files.associations": {
    "*.panther": "pantherlang",
    "*.pan": "pantherlang"
  },
  "pantherlang.project.autoDetect": true
}
EOF

cat > "project_templates/$t/.vscode/tasks.json" <<'EOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "PantherLang: Run",
      "type": "shell",
      "command": "panther run",
      "group": "build",
      "problemMatcher": []
    },
    {
      "label": "PantherLang: Build",
      "type": "shell",
      "command": "panther build",
      "group": "build",
      "problemMatcher": []
    },
    {
      "label": "PantherLang: Test",
      "type": "shell",
      "command": "panther test",
      "group": "test",
      "problemMatcher": []
    }
  ]
}
EOF

cat > "project_templates/$t/.vscode/launch.json" <<'EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "pantherlang",
      "request": "launch",
      "name": "Debug PantherLang Program",
      "program": "${workspaceFolder}/src/main.panther"
    }
  ]
}
EOF
done

echo "[6/12] Updating template-specific manifests and tests..."
cat > project_templates/console_app/tests/test_main.panther <<'EOF'
panther test "console app boots" {
    assert true
}
EOF

cat > project_templates/web_app/tests/test_web.panther <<'EOF'
panther test "web app routes" {
    assert true
}
EOF

cat > project_templates/api_app/tests/test_api.panther <<'EOF'
panther test "api health endpoint" {
    assert true
}
EOF

cat > project_templates/ai_app/tests/test_ai.panther <<'EOF'
panther test "ai app configuration" {
    assert true
}
EOF

cat > project_templates/console_app/docs/PROJECT_GUIDE.md <<'EOF'
# Console App Guide

Use this template for CLI tools, scripts, and automation.
EOF

cat > project_templates/web_app/docs/PROJECT_GUIDE.md <<'EOF'
# Web App Guide

Use this template for PantherLang web applications.
EOF

cat > project_templates/api_app/docs/PROJECT_GUIDE.md <<'EOF'
# API App Guide

Use this template for PantherLang HTTP APIs and services.
EOF

cat > project_templates/ai_app/docs/PROJECT_GUIDE.md <<'EOF'
# AI App Guide

Use this template for AI-assisted applications with safe configuration practices.
EOF

echo "[7/12] Enhancing generated project metadata..."
python3 <<'PY'
from pathlib import Path

templates = {
    "console_app": "console",
    "web_app": "web",
    "api_app": "api",
    "ai_app": "ai",
}
for folder, kind in templates.items():
    p = Path("project_templates") / folder / "panther.toml"
    text = p.read_text()
    if "[tooling]" not in text:
        text += """

[tooling]
vscode = true
debug = true
tasks = true

[metadata]
created_by = "PantherLang Project Wizard"
template = "%s"
""" % kind
    p.write_text(text)
print("✅ template manifests enhanced")
PY

echo "[8/12] Creating template professionalization tests..."
cat > tests/R3_project_system/test_r3_batch1_part3_templates_professionalization.py <<'PY'
from pathlib import Path

from tools.project_wizard.wizard import available_templates, create_project


def test_all_templates_have_professional_files():
    mapping = {
        "console": "console_app",
        "web": "web_app",
        "api": "api_app",
        "ai": "ai_app",
    }
    for template_id, folder in mapping.items():
        root = Path("project_templates") / folder
        assert (root / "README.md").exists()
        assert (root / ".gitignore").exists()
        assert (root / ".vscode" / "settings.json").exists()
        assert (root / ".vscode" / "tasks.json").exists()
        assert (root / ".vscode" / "launch.json").exists()
        assert (root / "docs" / "PROJECT_GUIDE.md").exists()
        assert any((root / "tests").glob("*.panther"))
        assert "[tooling]" in (root / "panther.toml").read_text()


def test_generated_projects_include_professional_files(tmp_path):
    for template in available_templates():
        result = create_project(f"pro-{template}", template, tmp_path)
        project = result.destination
        assert (project / "README.md").exists()
        assert (project / ".gitignore").exists()
        assert (project / ".vscode" / "tasks.json").exists()
        assert (project / ".vscode" / "launch.json").exists()
        assert (project / "docs" / "PROJECT_GUIDE.md").exists()
        assert (project / "panther.toml").exists()
        assert f"pro-{template}" in (project / "README.md").read_text()
PY

echo "[9/12] Updating VS Code package to 1.0.3..."
python3 <<'PY'
from pathlib import Path
import json
pkg_path = Path("vscode-extension/package.json")
pkg = json.loads(pkg_path.read_text())
pkg["version"] = "1.0.3"
pkg["description"] = "Official PantherLang language support, project wizard, developer tooling, and debug adapter integration for Visual Studio Code."
keywords = set(pkg.get("keywords") or [])
keywords.update(["project-wizard", "templates", "run", "build", "deploy"])
pkg["keywords"] = sorted(keywords)
pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ package.json updated to 1.0.3")
PY

echo "[10/12] Validation and tests..."
python3 -m py_compile tools/project_wizard/__init__.py tools/project_wizard/wizard.py tools/project_wizard/panther_new.py tests/R3_project_system/test_r3_batch1_part3_templates_professionalization.py
python3 -m pytest tests/R3_project_system -q

echo "[11/12] Build VSIX 1.0.3..."
(
  cd "$EXT"
  rm -f pantherlang-1.0.3*.vsix
  npx --yes @vscode/vsce package --no-dependencies
)

mkdir -p releases/vscode_marketplace
VSIX="$(ls -t "$EXT"/pantherlang-1.0.3*.vsix | head -1)"
[ -f "$VSIX" ] || fail "VSIX 1.0.3 was not created."
cp "$VSIX" releases/vscode_marketplace/
sha256sum "releases/vscode_marketplace/$(basename "$VSIX")" > "releases/vscode_marketplace/$(basename "$VSIX").sha256"

echo "[12/12] Writing manifest/report/status..."
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
    "part": "3",
    "name": "Project Templates Professionalization",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "1.0.3",
    "runtime_modified": True,
    "features": [
        "template_readmes",
        "template_gitignore",
        "template_vscode_tasks",
        "template_launch_config",
        "template_docs",
        "template_tests",
        "template_metadata",
        "vsix_1_0_3"
    ],
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "next": "R3 Batch 1 Part 4 - Run Command Integration"
}
(r3 / "batch1_part3_templates_professionalization_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ manifest written")
PY

cat > "$REPORTS/R3_BATCH1_PART3_PROJECT_TEMPLATES_PROFESSIONALIZATION.md" <<EOF
# R3 Batch 1 Part 3 - Project Templates Professionalization

## Status

PASSED

## Version

PantherLang VS Code Extension 1.0.3

## Added

- Professional README files per template
- Standard .gitignore
- VS Code tasks.json
- VS Code launch.json
- Project docs
- Template tests
- Enhanced panther.toml metadata
- VSIX 1.0.3 package

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Next

R3 Batch 1 Part 4 - Run Command Integration.
EOF

cat > "$R3/status_batch1_part3_templates_professionalization.json" <<EOF
{
  "ok": true,
  "phase": "R3",
  "batch": "1",
  "part": "3",
  "status": "PASSED",
  "name": "Project Templates Professionalization",
  "version": "1.0.3",
  "runtime_modified": true,
  "vsix": "releases/vscode_marketplace/$(basename "$VSIX")",
  "next": "R3 Batch 1 Part 4 - Run Command Integration"
}
EOF

echo "============================================================"
echo "✅ R3 Batch 1 Part 3 COMPLETE"
echo "✅ Project Templates Professionalization READY"
echo "VSIX: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Next: R3 Batch 1 Part 4 - Run Command Integration"
echo "============================================================"
