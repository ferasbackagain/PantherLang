# PantherLang H4.4 — D1 VS Code Debugger Contribution

Status: PASSED LOCALLY

## Scope
D1 adds the VS Code debugger contribution for PantherLang.

## Detected / Updated
- Extension package: vscode-extension/package.json
- Extension directory: vscode-extension

## Implemented
- contributes.debuggers
- Debugger type: panther
- Debugger label: PantherLang Debug
- Initial launch configuration
- activationEvents for debug
- language contribution for .pan and .panther
- command contribution: panther.debug.start
- .vscode/launch.json
- .vscode/tasks.json

## Verification
- package.json valid JSON.
- Debugger contribution regression passed.
- Language contribution regression passed.
- Command contribution regression passed.
- launch.json/tasks.json regression passed.
- H4.3 D10 compatibility regression re-run when present.

## Backup
.panther/backups/H4_4_d1_vscode_debugger_contribution_20260628_123651

## Next
H4.4 D2 Debug Adapter Registration.
