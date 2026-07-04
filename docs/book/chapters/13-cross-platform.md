# Chapter 13: Cross-Platform Development

PantherLang runs on any system with Python 3.10+:

- **Linux** — Ubuntu, Debian, Fedora, Arch, etc.
- **macOS** — 10.15+
- **Windows** — 10/11 via PowerShell or Command Prompt

## Cross-Platform Scripts

The repository includes runner scripts:

```bash
# Linux / macOS
bash scripts/run_examples.sh

# Windows PowerShell
.\scripts\run_examples.ps1

# Windows Command Prompt
scripts\run_examples.bat
```

## Path Handling

Filesystem functions use Python's `pathlib.Path`, ensuring correct path separators on all platforms.

## CI/CD

```bash
pip install -e ".[dev]"
python -m pytest
python -m build
```
