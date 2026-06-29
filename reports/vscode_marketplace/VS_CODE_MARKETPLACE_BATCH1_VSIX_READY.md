# VS Code Marketplace Pipeline - Batch 1

## Status

PASSED

## VSIX

`releases/vscode_marketplace/pantherlang-0.8.8.vsix`

## Local install command

```bash
code --install-extension releases/vscode_marketplace/pantherlang-0.8.8.vsix
```

## Publish command later

```bash
cd vscode-extension
npx --yes @vscode/vsce publish
```

Or with token:

```bash
cd vscode-extension
VSCE_PAT=<your_token> npx --yes @vscode/vsce publish
```

## Runtime modification

No PantherLang runtime source files were modified.

## Next

Batch 2 - Marketplace Publisher Validation + Publish Gate.
