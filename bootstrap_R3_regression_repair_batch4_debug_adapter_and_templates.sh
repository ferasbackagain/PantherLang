#!/usr/bin/env bash
set -Eeuo pipefail

PHASE="R3 Regression Repair Batch 4 - Debug Adapter Compatibility + PantherLang Templates"
STAMP="$(date +%Y%m%d_%H%M%S)"
ROOT="$(pwd)"

if [ ! -d "$ROOT/debug_adapter" ] || [ ! -d "$ROOT/tests" ]; then
  echo "ERROR: Run this script from the PantherLang repository root."
  echo "Current directory: $ROOT"
  exit 1
fi

BACKUP_DIR="$ROOT/.panther_backups/r3_regression_repair_batch4_${STAMP}"
mkdir -p "$BACKUP_DIR"

backup_if_exists() {
  local p="$1"
  if [ -e "$ROOT/$p" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$p")"
    cp -a "$ROOT/$p" "$BACKUP_DIR/$p"
  fi
}

backup_if_exists "debug_adapter/launcher.py"
backup_if_exists "debug_adapter/variables.py"
backup_if_exists "debug_adapter/__init__.py"
backup_if_exists "vscode-extension/src/extension.js"
backup_if_exists "vscode-extension/out/extension.js"
backup_if_exists "vscode-extension/package.json"
backup_if_exists "vscode-extension/project_templates"
backup_if_exists "vscode-extension/tools"

python3 - <<'PYTHON_PATCH'
from pathlib import Path
import json
import shutil

root = Path.cwd()

# ---------------------------------------------------------------------------
# 4.1 Launcher Compatibility
# ---------------------------------------------------------------------------
launcher = root / "debug_adapter" / "launcher.py"
launcher.write_text('''import os
import subprocess
from dataclasses import dataclass
from typing import Optional


@dataclass
class LaunchResult:
    command: list[str]
    cwd: Optional[str]
    pid: Optional[int]
    started: bool


class PantherProgramLauncher:
    """Production PantherLang program launcher.

    The modern launcher keeps process startup behind a dry_run gate so tests and
    IDE smoke checks can verify DAP launch behavior without spawning Panther.
    """

    def build_command(self, program, args=None):
        args = list(args or [])
        if not program:
            raise ValueError("launch requires a program path")
        return ["Panther", "run", program, *args]

    def launch(self, program, args=None, cwd=None, dry_run=True):
        command = self.build_command(program, args)
        if dry_run:
            return LaunchResult(command=command, cwd=cwd, pid=None, started=False)

        process = subprocess.Popen(
            command,
            cwd=cwd or os.getcwd(),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        return LaunchResult(command=command, cwd=cwd, pid=process.pid, started=True)


class Launcher(PantherProgramLauncher):
    """Legacy compatibility alias for older DAP tests/imports.

    Historical modules import ``debug_adapter.launcher.Launcher`` while the
    current production implementation is named ``PantherProgramLauncher``.
    Keeping this subclass preserves both public contracts without duplicating
    behavior.
    """

    pass


# Lowercase alias kept for old scripts that treated launcher as a factory name.
launcher = Launcher

__all__ = ["LaunchResult", "PantherProgramLauncher", "Launcher", "launcher"]
''', encoding='utf-8')

# ---------------------------------------------------------------------------
# 4.2 Variables public compatibility facade
# ---------------------------------------------------------------------------
variables = root / "debug_adapter" / "variables.py"
variables.write_text('''"""PantherLang Debug Adapter variables compatibility facade.

This module intentionally exports both the newer production services and the
legacy names used by H4/H4.2/H4.3 regression suites. Do not collapse these
imports into private-only modules; tests and extension integration import from
``debug_adapter.variables`` as a public API surface.
"""

from .variables_core import DebugVariable, VariableFactory, VariablesCore
from .variable_references import (
    ReferenceEntry,
    VariableReferenceAllocator,
    VariableReferenceResolver,
    VariableReferenceService,
)
from .variable_store import VariableScopeRecord, VariableStore, DebugVariableStore
from .stack_frames import StackFrameSource, DebugStackFrame, StackFrameStore
from .threads import DebugThread, ThreadStore, DebugThreadStore
from .scopes import DebugScope, ScopeStore, DebugScopeStore
from .evaluate import EvaluateResult, EvaluateContext, EvaluateEngine, DebugEvaluateEngine
from .watch_expressions import (
    WatchExpression,
    WatchExpressionStore,
    WatchExpressionManager,
    build_watch_manager_for_thread_store,
)

__all__ = [
    "DebugVariable",
    "VariableFactory",
    "VariablesCore",
    "ReferenceEntry",
    "VariableReferenceAllocator",
    "VariableReferenceResolver",
    "VariableReferenceService",
    "VariableScopeRecord",
    "VariableStore",
    "DebugVariableStore",
    "StackFrameSource",
    "DebugStackFrame",
    "StackFrameStore",
    "DebugThread",
    "ThreadStore",
    "DebugThreadStore",
    "DebugScope",
    "ScopeStore",
    "DebugScopeStore",
    "EvaluateResult",
    "EvaluateContext",
    "EvaluateEngine",
    "DebugEvaluateEngine",
    "WatchExpression",
    "WatchExpressionStore",
    "WatchExpressionManager",
    "build_watch_manager_for_thread_store",
]
''', encoding='utf-8')

# ---------------------------------------------------------------------------
# 4.3 Package public export compatibility
# ---------------------------------------------------------------------------
init = root / "debug_adapter" / "__init__.py"
init.write_text('''"""PantherLang Debug Adapter Protocol core package."""

__version__ = "0.4.1-batch4-compat"

from .adapter import PantherDebugAdapter
from .session import DebugSession
from .launcher import LaunchResult, Launcher, PantherProgramLauncher
from .server import DebugServer
from .dispatcher import RequestDispatcher
from .variables import (
    DebugVariable,
    VariableFactory,
    VariablesCore,
    VariableReferenceService,
    VariableStore,
    DebugVariableStore,
    StackFrameStore,
    ThreadStore,
    ScopeStore,
    EvaluateEngine,
    WatchExpressionStore,
)

__all__ = [
    "PantherDebugAdapter",
    "DebugSession",
    "LaunchResult",
    "Launcher",
    "PantherProgramLauncher",
    "DebugServer",
    "RequestDispatcher",
    "DebugVariable",
    "VariableFactory",
    "VariablesCore",
    "VariableReferenceService",
    "VariableStore",
    "DebugVariableStore",
    "StackFrameStore",
    "ThreadStore",
    "ScopeStore",
    "EvaluateEngine",
    "WatchExpressionStore",
    "__version__",
]
''', encoding='utf-8')

# ---------------------------------------------------------------------------
# 4.4 VS Code extension template packaging and installed-extension fallback.
# ---------------------------------------------------------------------------
ext_root = root / "vscode-extension"
if ext_root.exists():
    # Package templates and Python wizard into the VSIX so the New Project command
    # works after installation, not only from an opened repository workspace.
    src_templates = root / "project_templates"
    dst_templates = ext_root / "project_templates"
    if src_templates.exists():
        if dst_templates.exists():
            shutil.rmtree(dst_templates)
        shutil.copytree(src_templates, dst_templates, ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))

    src_tools = root / "tools" / "project_wizard"
    dst_tools = ext_root / "tools" / "project_wizard"
    if src_tools.exists():
        if dst_tools.exists():
            shutil.rmtree(dst_tools)
        shutil.copytree(src_tools, dst_tools, ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))

    for rel in ["src/extension.js", "out/extension.js"]:
        p = ext_root / rel
        if p.exists():
            text = p.read_text(encoding='utf-8')
            old = '''function findPantherRepoRoot(start) {
  const candidates = [];
  if (start) {
    candidates.push(start);
    candidates.push(path.dirname(start));
  }

  const extRoot = path.resolve(__dirname, '..', '..');
  candidates.push(extRoot);
  candidates.push(process.cwd());

  for (const base of candidates) {
    const script = path.join(base, 'tools', 'project_wizard', 'panther_new.py');
    if (fs.existsSync(script)) return base;
  }
  return undefined;
}'''
            new = '''function findPantherRepoRoot(start) {
  const candidates = [];
  if (start) {
    candidates.push(start);
    candidates.push(path.dirname(start));
  }

  const extensionRoot = path.resolve(__dirname, '..');
  const repoStyleRoot = path.resolve(__dirname, '..', '..');
  candidates.push(extensionRoot);
  candidates.push(repoStyleRoot);
  candidates.push(process.cwd());

  for (const base of candidates) {
    const script = path.join(base, 'tools', 'project_wizard', 'panther_new.py');
    const templatesDir = path.join(base, 'project_templates');
    if (fs.existsSync(script) && fs.existsSync(templatesDir)) return base;
    if (fs.existsSync(templatesDir)) return base;
  }
  return undefined;
}'''
            if old in text:
                text = text.replace(old, new)
            # Make the user-facing error precise but rarely reached after packaging.
            text = text.replace(
                "PantherLang templates are not available. Open the PantherLang repository workspace for this local test build.",
                "PantherLang templates are not available in this extension or workspace. Reinstall the latest PantherLang VSIX or open the PantherLang repository workspace."
            )
            p.write_text(text, encoding='utf-8')

    pkg = ext_root / "package.json"
    if pkg.exists():
        data = json.loads(pkg.read_text(encoding='utf-8'))
        files = data.setdefault("files", [])
        for item in ["project_templates/**", "tools/project_wizard/**"]:
            if item not in files:
                files.append(item)
        pkg.write_text(json.dumps(data, indent=2) + "\n", encoding='utf-8')

# ---------------------------------------------------------------------------
# Batch 4 manifests, report, and smoke tests.
# ---------------------------------------------------------------------------
panther_dir = root / ".panther" / "R3_compiler_runtime"
panther_dir.mkdir(parents=True, exist_ok=True)
manifest = {
    "phase": "R3 Regression Repair Batch 4",
    "name": "Debug Adapter Compatibility Layer + VS Code template packaging repair",
    "parts": {
        "4.1": "Launcher compatibility alias",
        "4.2": "Variables public facade compatibility",
        "4.3": "debug_adapter package public exports",
        "4.4": "VS Code extension packaged templates fallback",
        "4.5": "Targeted DAP/template smoke checks",
    },
    "policy": "No Feature Without Proof",
    "expected_effect": [
        "from debug_adapter.launcher import Launcher succeeds",
        "from debug_adapter.variables import VariableStore, VariablesCore succeeds",
        "server/dispatcher collection errors caused by Launcher are removed",
        "installed VSIX can create PantherLang templates without requiring repository workspace",
    ],
}
(panther_dir / "r3_regression_repair_batch4_debug_adapter_templates_manifest.json").write_text(json.dumps(manifest, indent=2), encoding='utf-8')
(root / ".panther" / "phase_status").mkdir(parents=True, exist_ok=True)
(root / ".panther" / "phase_status" / "R3_regression_repair_batch4_debug_adapter_templates.json").write_text(json.dumps({"status": "patched", **manifest}, indent=2), encoding='utf-8')

report = root / "reports" / "R3_REGRESSION_REPAIR_BATCH4_DEBUG_ADAPTER_TEMPLATES.md"
report.parent.mkdir(parents=True, exist_ok=True)
report.write_text('''# R3 Regression Repair Batch 4 — Debug Adapter Compatibility + Templates

## Scope

This batch repairs the remaining Debug Adapter compatibility collection failures
and fixes the VS Code extension project-template availability problem.

## Repairs

1. `debug_adapter.launcher`
   - Adds legacy `Launcher` alias/subclass.
   - Preserves `PantherProgramLauncher` as the production implementation.

2. `debug_adapter.variables`
   - Re-establishes the public compatibility facade for `VariableStore`,
     `VariablesCore`, `ThreadStore`, `ScopeStore`, `EvaluateEngine`, and watch APIs.

3. `debug_adapter.__init__`
   - Exports both legacy and production DAP APIs simultaneously.

4. VS Code extension templates
   - Copies `project_templates/` into `vscode-extension/project_templates/`.
   - Copies `tools/project_wizard/` into `vscode-extension/tools/project_wizard/`.
   - Adds both folders to the VSIX `files` allowlist.
   - Updates extension root detection so installed VSIX builds can create projects
     without requiring the repository workspace to be open.

## Verification commands

```bash
python3 - <<'PYCODE'
from debug_adapter.launcher import Launcher, PantherProgramLauncher
from debug_adapter.variables import VariableStore, VariablesCore
from debug_adapter import DebugServer, RequestDispatcher
print('Batch 4 import smoke: OK')
PYCODE

python3 -m pytest -q tests/test_h4_part2.py tests/test_h4_part3.py tests/test_h4_3_d3_variable_store.py tests/test_h4_3_d10_professional_verification.py
python3 -m pytest -q
```

## Next step after green DAP regression

Continue to `R3 Batch 2 Part 3.3 — Expression Parser`.
''', encoding='utf-8')
PYTHON_PATCH

python3 - <<'PYCODE'
from debug_adapter.launcher import Launcher, PantherProgramLauncher
from debug_adapter.variables import VariableStore, VariablesCore
from debug_adapter import DebugServer, RequestDispatcher
assert issubclass(Launcher, PantherProgramLauncher)
store = VariableStore()
store.create_scope('locals', {'x': 1})
assert store.variables('locals')[0]['name'] == 'x'
print('Batch 4 import/API smoke: PASSED')
PYCODE

python3 -m pytest -q \
  tests/test_h4_part2.py \
  tests/test_h4_part3.py \
  tests/test_h4_3_d3_variable_store.py \
  tests/test_h4_3_d10_professional_verification.py \
  tests/R3_project_system/test_r3_batch1_part1_project_wizard.py

cat <<EOF2

DONE: $PHASE
Backup: $BACKUP_DIR
Manifest: .panther/R3_compiler_runtime/r3_regression_repair_batch4_debug_adapter_templates_manifest.json
Report: reports/R3_REGRESSION_REPAIR_BATCH4_DEBUG_ADAPTER_TEMPLATES.md

Now run full regression:
  python3 -m pytest -q

If VS Code extension packaging is needed:
  cd vscode-extension
  npx @vscode/vsce package --no-dependencies
EOF2
