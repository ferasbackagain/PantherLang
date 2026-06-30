# R3 Batch C4 — VS Code String Contract Final Fix

Applied: 20260630_185253

Scope:
- Add missing onDebugInitialConfigurations activation event if absent.
- Ensure out/debugFlow.js contains exact F5 configuration name contract.
- Ensure out/extension.js contains provideDebugConfigurations and startPantherF5Debug contracts.
- Preserve existing extension behavior; patch is compatibility-oriented.

Next targeted regression:
python3 -m pytest -q \
  tests/test_h4_4_d1_vscode_debugger_contribution.py \
  tests/test_h4_4_d2_debug_adapter_registration.py \
  tests/test_h4_4_d4_f5_debug_flow.py \
  tests/test_h4_4_d5_vscode_extension_package_verification.py \
  tests/test_h4_4_d6_vscode_end_to_end_verification.py
