# PantherLang Marketplace Publish Dry Run

## Status

PASSED

## Artifact

`releases/vscode_marketplace/pantherlang-1.0.0.vsix`

## Publisher

`pantherlang`

## Extension ID expected

`pantherlang.pantherlang`

## Dry-run result

VSIX package exists, checksums validate, metadata validates, and VSCE package tree contains required Marketplace files.

## Manual pre-publish check

```bash
cd vscode-extension
npx --yes @vscode/vsce ls --tree
```

## Publish command with token

```bash
cd vscode-extension
VSCE_PAT=<your_marketplace_token> npx --yes @vscode/vsce publish --packagePath ../releases/vscode_marketplace/pantherlang-1.0.0.vsix
```

## Safer publish gate script

```bash
VSCE_PAT=<your_marketplace_token> bash .panther/R2_marketplace_professionalization/publish_from_vsix_gate.sh
```
