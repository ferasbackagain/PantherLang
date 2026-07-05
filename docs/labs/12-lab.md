# Lab 12: CLI & Tooling

## Objectives
- Run `panther doctor` to verify the system
- Scaffold a web project with `panther new web`
- Validate syntax with `panther check`

## Theory

The `panther` CLI provides these commands:

| Command | Description |
|---------|-------------|
| `panther run <file>` | Execute a `.pan` file |
| `panther run --serve <file>` | Execute with HTTP server |
| `panther check <file>` | Syntax validation (no execution) |
| `panther new console/web/api/ai <name>` | Scaffold a project |
| `panther doctor` | Verify all system components |
| `panther version` | Show version |

The VS Code extension (in `vscode-extension/`) provides syntax highlighting, snippets, and debug support.

## Exercises

### Exercise 1: Run `panther doctor`
**Task**: Run `python -m cli.panther_cli doctor` and examine the output. Identify which components are available.
**Hint**: The command checks Python version, compiler imports, stdlib registration, and template availability.
**Verify**: Review the output for "OK" indicators.

### Exercise 2: Scaffold a Web Project
**Task**: Run `python -m cli.panther_cli new web lab12_webapp` to scaffold a web project. List the created files.
**Hint**: The scaffold creates `main.pan`, `README.md`, and other project files. Use `ls -R` to explore.
**Verify**: Check that `lab12_webapp/main.pan` exists and contains a web template.

### Exercise 3: Run `panther check`
**Task**: Run `python -m cli.panther_cli check docs/labs/solutions/12-lab.pan` to validate syntax without execution.
**Hint**: This performs parsing, semantic analysis, and security analysis without running the code.
**Verify**: The command should exit cleanly with no errors.

## Summary
You used the PantherLang CLI to verify the system, scaffold projects, and validate code syntax — essential skills for daily development.

## Further Reading
- Book Chapter 12: CLI and Tooling
- docs/CLI_GUIDE.md
