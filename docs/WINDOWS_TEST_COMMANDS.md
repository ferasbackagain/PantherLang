# PantherLang Windows Test Commands

Test PantherLang locally on Windows 10/11.

## Prerequisites

```powershell
# Install Python 3.10+ from python.org (ensure "Add to PATH" is checked)
python --version

# Install Git from git-scm.com
git --version
```

## Install PantherLang

```powershell
# From PyPI
pip install pantherlang

# OR from source (Developer Edition)
git clone <repo-url> PantherLang
cd PantherLang
pip install -e ".[dev]"
```

## Verify Installation

```powershell
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

```powershell
# Console project
panther new console test_console
panther run test_console\main.pan

# Web project
panther new web test_web
panther run test_web\main.pan --serve

# API project
panther new api test_api
panther run test_api\main.pan --serve

# AI project
panther new ai test_ai
panther run test_ai\main.pan

# Note: --serve flag is recognized but full HTTP server
# integration is in development — mock output is shown
```

## Run All Examples

```powershell
# From repository root (PowerShell):
.\scripts\run_examples.ps1

# From Command Prompt:
scripts\run_examples.bat
```

## Run Tests

```powershell
# All example tests
python -m pytest tests\test_examples.py -q

# Full regression
python -m pytest -q

# Specific test files
python -m pytest tests\test_book_content.py -v
```

## Build Package

```powershell
pip install build wheel
python -m build
dir dist\
```

## VS Code Extension (Local Install)

```powershell
# Prerequisites: Install Node.js from nodejs.org
cd vscode-extension
npm install
npm install -g @vscode/vsce
vsce package
code --install-extension pantherlang-official-*.vsix
```

## Windows Path Notes

```powershell
# Use backslashes or forward slashes in file paths
# If panther command not found, check Python Scripts directory:
$env:Path += ";$env:APPDATA\Python\Scripts"
$env:Path += ";$env:LOCALAPPDATA\Programs\Python\Python313\Scripts"

# Use PowerShell for best experience
# CMD also works but quotes may need adjustment
```
