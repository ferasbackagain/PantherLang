# R3 Regression Repair Batch 4 — Debug Adapter Compatibility + Templates

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
