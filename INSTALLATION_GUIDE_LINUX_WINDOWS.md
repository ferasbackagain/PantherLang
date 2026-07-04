# PantherLang v1.1.5 Installation Guide — Linux & Windows

**Version:** 1.1.5
**Date:** 2026-07-04
**Python Requirement:** 3.10+

---

## Quick Install (All Platforms)

### From PyPI (Recommended)
```bash
pip install pantherlang
```

### Verify Installation
```bash
panther doctor
panther version
```

Expected output:
```
PantherLang v1.1.5 (PantherLang v1.1.5)
────────────────────────────
  Python               OK
  compiler             OK
  runtime              OK
  stdlib               OK
  types                OK
  web                  OK
  database             OK
  AI                   OK
  security             OK
  package mgr          OK
  templates            OK
────────────────────────────
PantherLang is ready.
```

---

## Linux Installation (Ubuntu/Debian/Fedora/Arch)

### Prerequisites
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install python3 python3-pip python3-venv

# Fedora
sudo dnf install python3 python3-pip

# Arch
sudo pacman -S python python-pip
```

### Install PantherLang
```bash
# Option 1: User install (recommended)
pip install --user pantherlang

# Option 2: Virtual environment (cleanest)
python3 -m venv ~/panther-env
source ~/panther-env/bin/env/bin/activate
pip install pantherlang

# Option 3: System-wide (requires sudo)
sudo pip install pantherlang
```

### Add to PATH (if user install)
```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"

# Reload
source ~/.bashrc
```

### Run Examples
```bash
# Clone examples (or use installed package)
git clone https://github.com/ferasbackagain/PantherLang
cd pantherlang/PantherLang_Developer_Edition_v0_5
bash scripts/run_examples.sh
```

### Create First Project
```bash
panther new console hello
panther run hello/src/main.panther
```

---

## Windows Installation (Windows 10/11)

### Prerequisites
1. **Install Python 3.10+** from [python.org](https://python.org/downloads)
   - ✅ Check "Add Python to PATH" during installation
2. **Open PowerShell as Administrator** (for system install) or regular PowerShell (for user install)

### Install PantherLang

#### Option A: User Install (Recommended, No Admin)
```powershell
pip install --user pantherlang
```

#### Option B: Virtual Environment (Cleanest)
```powershell
python -m venv ~/panther-env
~/panther-env/Scripts/Activate.ps1
pip install pantherlang
```

#### Option C: System Install (Requires Admin PowerShell)
```powershell
pip install pantherlang
```

### Verify PATH
If `panther` command not found after user install:
```powershell
# Find user site-packages
python -m site --user-site
# Add Scripts folder to PATH, e.g.:
$env:PATH += ";$HOME\AppData\Roaming\Python\Python313\Scripts"

# Permanent fix (PowerShell as Admin):
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$HOME\AppData\Roaming\Python\Python313\Scripts", "User")
```

### Run Examples (PowerShell)
```powershell
# Clone repository
git clone https://github.com/ferasbackagain/PantherLang
cd pantherlang\PantherLang_Developer_Edition_v0_5

# Run examples
.\scripts\run_examples.ps1
```

### Run Examples (Command Prompt)
```cmd
git clone https://github.com/ferasbackagain/PantherLang
cd pantherlang\PantherLang_Developer_Edition_v0_5
scripts\run_examples.bat
```

### Create First Project
```powershell
panther new console hello
panther run hello\src\main.panther
```

---

## VS Code Extension Installation

### From Marketplace (After Launch)
1. Open VS Code Extensions (Ctrl+Shift+X)
2. Search "PantherLang"
3. Click Install

### From Source (Developer Edition)
```bash
# Linux/macOS
cd vscode-extension
npm install
npm run package
code --install-extension pantherlang-1.1.5.vsix
```

```powershell
# Windows PowerShell
cd vscode-extension
npm install
npm run package
code --install-extension pantherlang-1.1.5.vsix
```

### VS Code Features
- Syntax highlighting for `.panther` / `.pan`
- Snippets: `pn-main`, `pn-fn`, `pn-let`, `pn-if`, `pn-while`, `pn-for`
- Debug adapter (F5 to debug)
- Project wizard: `Ctrl+Shift+P` → "PantherLang: New Project"
- Commands: Run, Build, Check, Doctor

---

## Development Install (From Source)

### Linux/macOS
```bash
git clone https://github.com/ferasbackagain/PantherLang
cd pantherlang/PantherLang_Developer_Edition_v0_5
pip install -e ".[dev]"
```

### Windows PowerShell
```powershell
git clone https://github.com/ferasbackagain/PantherLang
cd pantherlang\PantherLang_Developer_Edition_v0_5
pip install -e ".[dev]"
```

### Verify Development Install
```bash
python -m pytest tests/ -q
# Should show: 1039 passed in ~90s
```

---

## Cross-Platform Runner Scripts

The repository includes platform-specific runners:

| Platform | Script | Usage |
|----------|--------|-------|
| Linux/macOS | `scripts/run_examples.sh` | `bash scripts/run_examples.sh` |
| Windows PowerShell | `scripts/run_examples.ps1` | `.\scripts\run_examples.ps1` |
| Windows CMD | `scripts/run_examples.bat` | `scripts\run_examples.bat` |

All run the same 11 verified examples.

---

## Troubleshooting

### `panther: command not found`
- **Linux/macOS**: Add `~/.local/bin` to PATH
- **Windows**: Add Python Scripts folder to PATH (see above)

### `ModuleNotFoundError: No module named 'compiler'`
- Run `pip install -e ".[dev]"` from repo root
- Or `pip install pantherlang` from PyPI

### `panther doctor` shows FAIL
- Ensure Python 3.10+
- Run `pip install -e ".[dev]"` to get all dependencies
- Check `pip list | grep -E "panther|pytest|requests"`

### Permission denied on scripts
```bash
chmod +x scripts/*.sh
```

### Windows execution policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Uninstall

```bash
# PyPI install
pip uninstall pantherlang

# Development install
pip uninstall pantherlang
# Then remove repo folder
```

---

## Support

- **Documentation:** `docs/` in repository or GitHub Pages
- **Issues:** GitHub Issues
- **Discord:** PantherLang community (invite in README)
- **Email:** feras@pantherlang.org

---

*PantherLang v1.1.5 — Modern, Secure, AI-Native, Cross-Platform*