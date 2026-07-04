# PantherLang Developer Guide

## Development Setup

```bash
git clone https://github.com/ferasbackagain/PantherLang.git
cd pantherlang
pip install -e ".[dev]"
```

## Running Tests

```bash
# Full regression
python -m pytest

# Specific test directory
python -m pytest tests/security/

# With verbose output
python -m pytest -v --tb=short
```

## Building the Package

```bash
# Install build tools
pip install build

# Build wheel and source distribution
python -m build

# Built artifacts in dist/
```

## Publishing to PyPI

```bash
pip install twine
python -m build
twine upload dist/*
```

## VS Code Extension

The VS Code extension is at `vscode-extension/`:

```bash
cd vscode-extension
npm install
npm run compile
vsce package
```

## Project Structure

- `compiler/` — Core compiler pipeline
- `cli/` — CLI entry point
- `panther_core/` — Version metadata
- `package_manager/` — Package management
- `tests/` — Test suite (942+ tests)
- `project_templates/` — Project scaffolds
- `vscode-extension/` — VS Code extension
- `tools/` — LSP server, project wizard, toolchain

## Adding a New Standard Library Function

1. Add the implementation to `compiler/stdlib/functions.py`
2. Register with `_register(StdlibFunction(...))`
3. Add tests to the appropriate test file
4. Run full regression

## Adding a New Compiler Diagnostic

1. Add check logic to `compiler/semantic/analyzer.py` or `compiler/types/checker.py`
2. Use a new error code (e.g., E009)
3. Add diagnostic class to `compiler/semantic/diagnostics.py`
4. Add tests

## Cross-Platform Notes

- All paths use `pathlib.Path` — no hardcoded `/` paths
- Line endings handled generically
- Python 3.10+ required
- Works on Linux, Windows, and macOS
