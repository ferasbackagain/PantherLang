# PantherLang Kali Linux Test Commands

Test PantherLang locally on Kali Linux (Debian-based).

## Prerequisites

```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv git -y
```

## Install PantherLang

```bash
# From PyPI
pip install pantherlang

# OR from source (Developer Edition)
git clone <repo-url> PantherLang
cd PantherLang
pip install -e ".[dev]"
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
python -m pytest tests/test_examples.py -q

# Full regression
python -m pytest -q

# Specific test files
python -m pytest tests/test_book_content.py -v
python -m pytest tests/test_docs_presence.py -v
python -m pytest tests/security/test_web_security.py -v
```

## Build Package

```bash
pip install build
python -m build
ls dist/
```

## VS Code Extension (Local Install)

```bash
cd vscode-extension
npm install
npm install -g @vscode/vsce
vsce package
code --install-extension pantherlang-official-*.vsix
```

## Path Notes (Kali)

```bash
# Python 3 is default on Kali
python3 --version
python3 -m pip install pantherlang

# If you get "externally-managed-environment" error:
python3 -m venv panther-env
source panther-env/bin/activate
pip install pantherlang
```
