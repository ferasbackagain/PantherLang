# VS Code Local Release Test

Test the PantherLang VS Code extension locally before Marketplace release.

## Extension Files

Verify these exist:

- `vscode-extension/package.json`
- `vscode-extension/README.md`
- `vscode-extension/CHANGELOG.md`
- `vscode-extension/src/extension.js`
- `vscode-extension/syntaxes/panther.tmLanguage.json`
- `vscode-extension/icons/panther-icon.png`

## Prerequisites

```bash
# Node.js 18+ required
node --version
npm --version
```

## Build Extension

```bash
cd vscode-extension
npm install
npm install -g @vscode/vsce
vsce package
```

This creates `pantherlang-official-*.vsix` in the current directory.

## Install Locally

```bash
code --install-extension pantherlang-official-*.vsix
```

Or install via VS Code UI:
1. Open VS Code
2. Extensions panel (Ctrl+Shift+X)
3. "..." menu → Install from VSIX
4. Select the `.vsix` file

## Verify Installation

Open a `.panther` or `.pan` file and check:

| Feature | How to Verify | Expected |
|---------|--------------|----------|
| File icon | File explorer shows Panther icon | Panther icon for `.panther`/`.pan` |
| Syntax highlighting | Open `.pan` file | Keywords (`panther`, `main`, `fn`, `let`, `if`, `while`, `for`, `return`, `print`) highlighted |
| Snippets | Type `pn-` in .panther file | Auto-complete shows: `pn-main`, `pn-fn`, `pn-let`, `pn-if`, `pn-while`, `pn-for` |
| Run command | Ctrl+Shift+P → "Panther: Run File" | Executes current file |
| Build command | Ctrl+Shift+P → "Panther: Build" | Builds current file |
| New project | Ctrl+Shift+P → "Panther: New Project" | Prompts for type and name |

## Debug Configuration

Check debug config in `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "panther",
            "request": "launch",
            "name": "Run Panther File",
            "program": "${file}"
        }
    ]
}
```

## Update package.json

Before packaging for Marketplace, update:

- `version` — increment according to semver
- `repository.url` — set to your GitHub URL
- `publisher` — set to your publisher name

## Test Uninstall

```bash
code --uninstall-extension pantherlang
```
