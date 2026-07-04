# Start Here for Developers

## What is PantherLang?

PantherLang is a modern, secure, AI-native programming language. It features:

- Tree-walking interpreter with full pipeline: lexer → parser → AST → semantic analysis → type checking → runtime
- 43 built-in standard library functions (string, math, JSON, filesystem, HTTP, SQLite, crypto, regex, collections)
- Security-native: secrets detection, sandbox, path traversal prevention, prompt injection detection
- AI-native: OpenAI, Anthropic, Gemini, Ollama, OpenRouter providers, Agents, SecureAgent, RAG
- Cross-platform: runs on Linux, macOS, Windows via Python 3.10+
- VS Code extension with syntax highlighting, snippets, debug adapter, LSP

## Install Locally

```bash
# From PyPI
pip install pantherlang

# Or from source (Developer Edition)
git clone <repository-url>
cd PantherLang_Developer_Edition_v0_5
pip install -e ".[dev]"
```

## Verify Installation

```bash
panther doctor
panther version
```

## Run Your First Program

```bash
panther run examples/console_hello/main.pan
```

Expected output:
```
Hello from PantherLang
Year: 2026
Version: 1.0.0
Is programming fun? true
Greetings: welcome to the Panther ecosystem
```

## Where the Real Examples Are

All verified, runnable examples are in `examples/`:

| Example | Run Command | What It Shows |
|---------|-------------|---------------|
| console_hello | `panther run examples/console_hello/main.pan` | Variables, functions, print |
| calculator | `panther run examples/calculator/calc.pan` | Arithmetic, recursion, if |
| json_parser | `panther run examples/json_parser/main.pan` | JSON encode/decode, objects |
| sqlite_crud | `panther run examples/sqlite_crud/main.pan` | Database CRUD operations |
| file_manager | `panther run examples/file_manager/main.pan` | Filesystem operations |
| http_client | `panther run examples/http_client/main.pan` | HTTP GET/POST |
| config_loader | `panther run examples/config_loader/main.pan` | Config file reading |
| security_audit_demo | `panther run examples/security_audit_demo/main.pan` | Security audit patterns |
| hello_api | `panther run examples/hello_api/main.pan` | API template |
| hello_web | `panther run examples/hello_web/main.pan` | Web template |
| hello_ai | `panther run examples/hello_ai/main.pan` | AI provider info |

## Run All Examples

```bash
bash scripts/run_examples.sh
python -m pytest tests/test_examples.py -v
```

## Open in VS Code

```bash
code .
```

The VS Code extension at `vscode-extension/` provides syntax highlighting for `.panther` and `.pan` files.

For local extension install:

```bash
cd vscode-extension
npm install
npm install -g @vscode/vsce
vsce package
code --install-extension pantherlang-official-*.vsix
```

## Create a New Project

```bash
panther new console my_app
cd my_app
panther run src/main.panther
```

Other project types: `web`, `api`, `ai`.

```bash
panther new web my_web_app
panther new api my_api
panther new ai my_ai_agent
```

## Test

```bash
# Full regression
python -m pytest -q

# Example tests only
python -m pytest tests/test_examples.py -v

# Book/content tests
python -m pytest tests/test_book_content.py -v
```

## How to Report Issues

Open an issue on GitHub or report at the repository's issue tracker.

## Current Limitations

- The `--serve` flag is recognized but does not start a full HTTP server from PantherLang source — it prints mock output
- Enums and traits are parsed but not fully operational at runtime
- Module imports work but the module resolution system is in active development
- Package manager has Python API but no CLI integration for `panther install`
- Debug adapter is implemented but requires VS Code extension for full debug experience
- Some phase demo files (`.panther` extension) use an older regex-based pipeline, not the main Pratt parser pipeline

## Documentation

- `docs/book/THE_PANTHER_PROGRAMMING_LANGUAGE.md` — Full language book
- `docs/book/chapters/` — Individual chapter files
- `docs/KALI_TEST_COMMANDS.md` — Kali Linux test guide
- `docs/WINDOWS_TEST_COMMANDS.md` — Windows test guide
- `docs/MACOS_TEST_COMMANDS.md` — macOS test guide
- `docs/book/examples-index.md` — Example index
- `docs/book/language-feature-map.md` — Feature-to-example mapping
