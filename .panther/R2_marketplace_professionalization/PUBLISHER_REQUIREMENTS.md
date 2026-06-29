# PantherLang VS Code Marketplace Publisher Requirements

To publish PantherLang to the VS Code Marketplace, prepare:

1. Microsoft / Azure DevOps account.
2. Visual Studio Marketplace publisher ID.
3. Personal Access Token with Marketplace Manage permission.
4. `vsce` publisher login or `VSCE_PAT` environment variable.
5. Confirm final publisher name in `vscode-extension/package.json`.

Commands later:

```bash
cd vscode-extension
npx --yes @vscode/vsce login <publisher-id>
npx --yes @vscode/vsce publish
```

Or:

```bash
cd vscode-extension
VSCE_PAT=<token> npx --yes @vscode/vsce publish
```
