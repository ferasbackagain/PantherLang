# PantherLang AI Agent Guide

## Quick Facts

- **Language**: PantherLang (`.panther`, `.pan`)
- **Version**: 2.0.0
- **Package**: `pip install pantherlang`
- **CLI**: `panther run/build/check/new/doctor`
- **Tests**: `python -m pytest` (1039+ tests)
- **Python**: 3.10+

## Project Structure

```
pantherlang/
├── compiler/          # Lexer → Parser → AST → Semantic → Type → Runtime
│   ├── lexer/         # Tokenizer (panther_lex.py, tokens.py)
│   ├── parser/        # Pratt expression parser + recursive descent
│   ├── ast/           # Frozen dataclass AST nodes
│   ├── semantic/      # Symbol table, scope, diagnostics
│   ├── types/         # Primitive types, type checker, inference
│   ├── runtime/       # Tree-walking interpreter
│   ├── stdlib/        # 54 stdlib functions (string, math, JSON, time,
│   │                  #   crypto, filesystem, HTTP, regex, collections, SQLite)
│   ├── security/      # Security analyzer, sandbox, web/ai security
│   ├── web/           # HTTP server, routing, security middleware
│   ├── ai/            # AI providers, agents, RAG, secure agent
│   └── database/      # SQLite engine, ORM, migrations
├── cli/               # panther command entry point (panther_cli.py)
├── panther_core/      # Version info
├── package_manager/   # Dependency resolution, lock files, security
├── project_templates/ # Scaffolds: console, web, api, ai
├── tests/             # Full test suite (48 subdirs, 1006+ tests)
├── vscode-extension/  # VS Code extension v2.0.0 (syntax, debug, wizard)
├── docs/              # Architecture, CLI, security, dev guides, language ref
│   └── specification/ # 8-spec formal language reference
├── examples/          # 6 runnable examples + 68 phase demo files
└── scripts/           # Cross-platform runners (sh, ps1, bat)
```

## Key Commands for AI Agents

```bash
# Full regression (REQUIRED before any PR)
python -m pytest

# Single test file
python -m pytest tests/security/test_web_security.py -v

# Run specific batch tests
python -m pytest tests/test_array_dict_support.py -v
python -m pytest tests/test_stdlib_phase6.py -v
python -m pytest tests/test_web_api_ai_runtime.py -v

# Build package
python -m build

# Run CLI
python -m cli.panther_cli doctor
python -m cli.panther_cli run examples/console_hello/main.pan

# Run all examples
bash scripts/run_examples.sh
```

## Language Feature Highlights

- **Parser**: Pratt expression parser + recursive descent statement parser, error recovery
- **Variables**: `let` with type inference, optional type annotations (`let x: int = 42`)
- **Functions**: `fn` with recursion, closures, parameters, return types
- **Control flow**: `if/elif/else`, `while`, `for i in 1..10`, `loop`, `break/continue`
- **Data types**: int, float, string, bool, null, any; struct, enum, trait
- **Collections**: Arrays (`[1, 2, 3]`), objects/dicts (`{x: 1, y: 2}`), indexing (`arr[0]`, `obj["key"]`)
- **Type system**: Primitive types, inference, annotations, compatibility checks (T001)
- **Semantic analysis**: Symbol tables, scope resolution, duplicate detection (E001-E008)
- **Stdlib categories**: String (11), Math (10), JSON (2), Time (2), Type conversion (3), Crypto (4), Security (2), Filesystem (6), HTTP (2), Regex (3), Collections (4), SQLite (4)

## Security Rules

1. Never hardcode API keys — use environment variables
2. Always sanitize file paths with `sanitize_path()`
3. Enable prompt injection detection for AI agents
4. Use `SecureAgent` instead of `Agent` in production
5. Enable sandbox for untrusted code execution
6. Security diagnostics (S001-S005) run during linting

## Architecture

The compiler follows a standard pipeline:

```
Source → Lexer → Token Stream → Parser → AST
        → Semantic Analysis → Type Check → Runtime → Output
```

Two pipelines co-exist:
- **Formal pipeline** (`compiler/parser/`, `compiler/semantic/`, `compiler/types/`, `compiler/runtime/`): tree-walking interpreter, full AST
- **Phase 6 pipeline** (`compiler/pipeline/`): regex-based, legacy

## Development

```bash
pip install -e ".[dev]"
python -m pytest
python -m build
```

## Package Distribution

```bash
python -m build
twine upload dist/*
```

## Engineering Principles

1. Always run full regression before declaring success
2. 0 failed, 0 errors — never skip or hide failures
3. Priority: Language → Compiler → Semantic → Types → Runtime → Stdlib → Applications → CLI → VS Code → Docs → Book
4. Never redesign architecture; always extend existing implementation
5. Repository is the single source of truth
