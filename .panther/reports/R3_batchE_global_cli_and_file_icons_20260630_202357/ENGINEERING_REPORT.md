# R3_batchE_global_cli_and_file_icons

Applied at: 20260630_202357

## Changes
- Replaced global `~/.local/bin/panther` with a stable wrapper pointing to this repository root.
- Added VS Code file icon theme for `.pan` and `.panther` files.
- Added icon theme contribution to `vscode-extension/package.json`.

## Verification commands
```bash
hash -r
which panther
panther version
panther check examples/hello.pan
python3 -m pytest -q
cd vscode-extension && npx vsce package
```
