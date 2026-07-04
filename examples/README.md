# PantherLang Examples

This directory contains real, executable PantherLang example projects.

## Examples

| # | Example | Description | Run |
|---|---------|-------------|-----|
| 1 | `console_hello/` | Variables, literals, expressions, functions | `panther run examples/console_hello/main.pan` |
| 2 | `calculator/` | Arithmetic, comparison, recursion | `panther run examples/calculator/calc.pan` |
| 3 | `hello_api/` | API template structure | `panther run examples/hello_api/main.pan` |
| 4 | `hello_web/` | Web template structure | `panther run examples/hello_web/main.pan` |
| 5 | `hello_ai/` | AI provider abstraction, mock mode | `panther run examples/hello_ai/main.pan` |
| 6 | `security_audit_demo/` | Defensive security audit demo | `panther run examples/security_audit_demo/main.pan` |
| 7 | `file_manager/` | Filesystem operations (read/write/list/remove) | `panther run examples/file_manager/main.pan` |
| 8 | `sqlite_crud/` | SQLite database CRUD operations | `panther run examples/sqlite_crud/main.pan` |
| 9 | `http_client/` | HTTP GET/POST requests | `panther run examples/http_client/main.pan` |
| 10 | `json_parser/` | JSON encode/decode with nested data | `panther run examples/json_parser/main.pan` |
| 11 | `config_loader/` | JSON configuration file read/parse | `panther run examples/config_loader/main.pan` |

## Running All Examples

```bash
# Linux / macOS
bash scripts/run_examples.sh

# Windows PowerShell
powershell -ExecutionPolicy Bypass -File scripts/run_examples.ps1

# Windows CMD
scripts\run_examples.bat
```
