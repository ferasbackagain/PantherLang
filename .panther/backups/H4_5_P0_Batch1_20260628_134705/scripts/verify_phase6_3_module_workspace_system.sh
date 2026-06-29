#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo " PantherLang Phase 6.3 PRO Verification"
echo "============================================================"

PYTHON_BIN="${PYTHON:-python3}"

if [ ! -f "language/compiler/workspace/workspace_manager.py" ]; then
  echo "❌ workspace_manager.py missing"
  exit 1
fi
if [ ! -f "tests/phase6_3/test_workspace_manager.py" ]; then
  echo "❌ phase6_3 pytest suite missing"
  exit 1
fi
if [ ! -f "docs/phase6/PHASE_6_3_MODULE_WORKSPACE_SYSTEM.md" ]; then
  echo "❌ phase 6.3 documentation missing"
  exit 1
fi
echo "✅ structure tests passed"

$PYTHON_BIN - <<'PY'
from language.compiler.workspace import WorkspaceManager
manager = WorkspaceManager()
assert manager.phase == "6.3"
assert manager.version == "0.6.3-module-workspace-system"
print("✅ manifest tests passed")
PY

if ! $PYTHON_BIN -m pytest --version >/dev/null 2>&1; then
  echo "⚠️ pytest missing for $PYTHON_BIN — installing locally for this interpreter"
  $PYTHON_BIN -m pip install -U pip pytest
fi

$PYTHON_BIN -m pytest -q tests/phase6_3

echo "✅ pytest regression suite passed"

bash scripts/run_phase6_3_practical_demo.sh

echo "✅ practical demo passed"

$PYTHON_BIN - <<'PY'
from pathlib import Path
import json
import tempfile
from language.compiler.workspace import WorkspaceError, WorkspaceManager

with tempfile.TemporaryDirectory() as d:
    root = Path(d) / "bad_ws"
    root.mkdir()
    (root / "panther.workspace.json").write_text(json.dumps({"name":"bad", "modules": []}), encoding="utf-8")
    try:
        WorkspaceManager(cache_dir=Path(d) / "cache").load_manifest(root)
    except WorkspaceError:
        print("✅ negative tests passed")
    else:
        raise SystemExit("negative test failed")
PY

$PYTHON_BIN - <<'PY'
from pathlib import Path
import json
import tempfile
from language.compiler.workspace import WorkspaceManager

with tempfile.TemporaryDirectory() as d:
    root = Path(d) / "stress_ws"
    root.mkdir()
    modules = []
    previous = None
    for i in range(25):
        name = f"m{i:02d}"
        mod_root = root / name
        mod_root.mkdir()
        imports = f"import {previous}\n" if previous else ""
        (mod_root / f"{name}.panther").write_text(imports + f"fn {name}() {{ return {i} }}\n", encoding="utf-8")
        modules.append({"name": name, "root": name, "sources": ["*.panther"]})
        previous = name
    (root / "panther.workspace.json").write_text(json.dumps({"name":"stress", "modules": modules}), encoding="utf-8")
    manager = WorkspaceManager(cache_dir=Path(d) / "cache")
    validation = manager.validate_workspace(root)
    assert len(validation["build_order"]) == 25
    assert validation["build_order"][0] == "m00"
    assert validation["build_order"][-1] == "m24"
print("✅ stress tests passed")
PY

echo "✅ PantherLang Phase 6.3 Module & Workspace System verification completed"
