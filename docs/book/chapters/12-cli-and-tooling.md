# Chapter 12: CLI and Tooling

## CLI Reference

| Command | Description |
|---------|-------------|
| `panther run <file>` | Execute a .panther/.pan file |
| `panther run --serve <file>` | Execute with HTTP server |
| `panther build <file>` | Build to shell artifact script |
| `panther check <file>` | Syntax, semantic, and security analysis (S001-S005) |
| `panther fmt <file>` | Validate and print source |
| `panther new console <name>` | Scaffold console project |
| `panther new web <name>` | Scaffold web project |
| `panther new api <name>` | Scaffold API project |
| `panther new ai <name>` | Scaffold AI project |
| `panther doctor` | Verify all system components |
| `panther version` | Show version information |

## VS Code Extension

The extension at `vscode-extension/` provides:
- Syntax highlighting for `.panther` and `.pan` files
- Code snippets for common constructs (`pn-main`, `pn-fn`, `pn-let`, etc.)
- Debug adapter protocol support
- LSP server integration

Install from the repository:

```bash
cd vscode-extension
npm install && npm run package
code --install-extension pantherlang-1.1.5.vsix
```

## Project Templates

```bash
panther new console my_app     # Creates main.pan with panther main { }
panther new web my_web_app     # Creates web project structure
panther new api my_api         # Creates API project structure
panther new ai my_ai_app       # Creates AI project structure
```
