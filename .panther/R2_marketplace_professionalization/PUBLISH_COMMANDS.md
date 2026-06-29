# PantherLang VS Code Marketplace Publish Commands

## Publisher

`pantherlang`

## VSIX

`releases/vscode_marketplace/pantherlang-1.0.0.vsix`

## Local install test

```bash
code --install-extension releases/vscode_marketplace/pantherlang-1.0.0.vsix
```

## Interactive Marketplace login

```bash
cd vscode-extension
npx --yes @vscode/vsce login pantherlang
npx --yes @vscode/vsce publish
```

## Non-interactive token publish

```bash
cd vscode-extension
VSCE_PAT=<your_marketplace_token> npx --yes @vscode/vsce publish
```

## Safer publish from VSIX

```bash
cd vscode-extension
VSCE_PAT=<your_marketplace_token> npx --yes @vscode/vsce publish --packagePath ../releases/vscode_marketplace/pantherlang-1.0.0.vsix
```
