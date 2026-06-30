# R3_batch4_v5_protocol_templates_release_contract

Status: applied
Timestamp: 20260630_182353

Fixed:
- debug_adapter/protocol.py unterminated f-string / DAP framing syntax error.
- DAP encode/decode/read compatibility.
- VS Code extension version activation string alignment with package.json.
- Template presence guard for project_templates and vscode-extension/project_templates.

Backup:
/home/panther/pantherlang/PantherLang_Developer_Edition_v0_5/.panther/backups/R3_batch4_v5_protocol_templates_release_contract_20260630_182353

Next verification:
python3 -m pytest -q tests/H4_1/test_debug_adapter_core.py tests/test_h4_3_d2_variables_references.py tests/test_h4_3_d3_variable_store.py tests/R3_project_system/test_r3_batch1_part3_templates_professionalization.py tests/R3_project_system/test_r3_batch1_1_1_command_activation_fix.py

Then:
python3 -m pytest -q
