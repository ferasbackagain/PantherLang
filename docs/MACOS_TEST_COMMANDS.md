# PantherLang macOS Test Commands

Test PantherLang locally on macOS (10.15+).

## Prerequisites

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Python 3 is pre-installed on macOS
python3 --version

# Install pip if needed
python3 -m ensurepip --upgrade
```

## Install PantherLang

```bash
# From PyPI
python3 -m pip install pantherlang

# OR from source (Developer Edition)
git clone <repo-url> PantherLang
cd PantherLang
python3 -m pip install -e ".[dev]"
```

## Verify Installation

```bash
panther version
panther doctor
panther --help
```

Expected output for `panther doctor`:
```
PantherLang Doctor
Lexer: OK
Parser: OK
AST: OK
Semantic: OK
Type Checker: OK
Runtime: OK
Stdlib: OK
Security: OK
Web: OK
AI: OK
Database: OK
```

## Create and Run Projects

```bash
# Console project
panther new console test_console
panther run test_console/main.pan

# Web project
panther new web test_web
panther run test_web/main.pan --serve

# API project
panther new api test_api
panther run test_api/main.pan --serve

# AI project
panther new ai test_ai
panther run test_ai/main.pan

# Note: --serve flag is recognized but full HTTP server
# integration is in development — mock output is shown
```

## Run All Examples

```bash
# From repository root:
bash scripts/run_examples.sh
```

## Run Tests

```bash
# All example tests
python3 -m pytest tests/test_examples.py -q

# Full regression
python3 -m pytest -q

# Specific test files
python3 -m pytest tests/test_book_content.py -v
```

## Build Package

```bash
python3 -m pip install build wheel
python3 -m build
ls dist/
```

## VS Code Extension (Local Install)

```bash
# Prerequisites: Install Node.js from nodejs.org
cd vscode-extension
npm install
npm install -g @vscode/vsce
vsce package
code --install-extension pantherlang-official-*.vsix
```

## macOS Path Notes

```bash
# If panther command not found:
export PATH="$PATH:$HOME/Library/Python/3.x/bin"

# Use python3 explicitly (not python)
alias python=python3
```
