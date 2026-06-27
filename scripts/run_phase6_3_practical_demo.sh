#!/usr/bin/env bash
set -euo pipefail

DEMO_DIR="build/phase6_3_demo_workspace"
rm -rf "$DEMO_DIR"
mkdir -p "$DEMO_DIR/core" "$DEMO_DIR/security" "$DEMO_DIR/app"

cat > "$DEMO_DIR/core/core.panther" <<'PANTHER'
fn normalize(value) {
  return value
}
PANTHER

cat > "$DEMO_DIR/security/policy.panther" <<'PANTHER'
import core
fn allow(user) {
  return core.normalize(user)
}
PANTHER

cat > "$DEMO_DIR/app/main.panther" <<'PANTHER'
import core
import security
fn main() {
  return security.allow("analyst")
}
PANTHER

cat > "$DEMO_DIR/panther.workspace.json" <<'JSON'
{
  "name": "phase6_3_demo_workspace",
  "version": "0.6.3",
  "entry": "app.main",
  "modules": [
    {"name": "core", "root": "core", "sources": ["*.panther"]},
    {"name": "security", "root": "security", "sources": ["*.panther"]},
    {"name": "app", "root": "app", "sources": ["*.panther"]}
  ]
}
JSON

python3 - <<'PY'
from language.compiler.workspace import WorkspaceManager
manager = WorkspaceManager(cache_dir="build/workspace_cache/demo")
validation = manager.validate_workspace("build/phase6_3_demo_workspace")
print("workspace:", validation["modules"][0]["root"], "...")
print("build order:", validation["build_order"])
assert validation["build_order"] == ["core", "security", "app"]
result = manager.build_workspace("build/phase6_3_demo_workspace")
print("modules built:", result.modules_built)
print("source count:", result.source_count)
assert result.ok is True
assert result.module_count == 3
assert result.external_api_used is False
assert result.network_required is False
PY

echo "✅ PantherLang Phase 6.3 practical demo passed"
