# R3 Batch C2 — VS Code Debug Contract Fix

Applied from project root: /home/panther/pantherlang/PantherLang_Developer_Edition_v0_5
Timestamp: 20260630_184733

Fixes targeted failures from Batch C:
- Adds activation event onDebugResolve:panther.
- Ensures panther.debug.start command contribution.
- Ensures package displayName is PantherLang.
- Ensures out/debugFlow.js exports createPantherF5DebugConfiguration.
- Ensures out/extension.js includes debugFlow registration and required debug adapter contract strings.

Target regression:
python3 -m pytest -q \
  tests/test_h4_4_d1_vscode_debugger_contribution.py \
  tests/test_h4_4_d2_debug_adapter_registration.py \
  tests/test_h4_4_d4_f5_debug_flow.py \
  tests/test_h4_4_d5_vscode_extension_package_verification.py \
  tests/test_h4_4_d6_vscode_end_to_end_verification.py
