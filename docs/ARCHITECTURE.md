# PantherLang Architecture

## Core Pipeline

```
Source (.panther) → Lexer → Token Stream → Parser → AST → Semantic Analysis → Type Check → Runtime Execution
```

## Directory Structure

```
pantherlang/
├── compiler/          # Compiler pipeline
│   ├── lexer/         # Tokenizer (lex_source)
│   ├── parser/        # Program parser (ProgramParser, TokenStream)
│   ├── ast/           # Frozen dataclass AST nodes
│   ├── semantic/      # Semantic analyzer, symbol table, scope, diagnostics
│   ├── types/         # Type system: TypeBase, TypeChecker
│   ├── runtime/       # Execution engine: StatementExecutor, ExpressionEvaluator, VariableEnvironment
│   ├── stdlib/        # Standard library functions
│   ├── web/           # Web server: HttpServer, Router, security middleware
│   ├── database/      # ORM: SqliteEngine, QueryBuilder, Migration
│   ├── ai/            # AI providers, agents, RAG, vector store
│   ├── security/      # Security analyzer, sandbox, web/ai security modules
│   └── pipeline/      # Alternative pipeline (Phase 6)
├── cli/               # CLI entry point (panther command)
├── panther_core/      # Version metadata
├── package_manager/   # Package manager, dependency resolution, security
├── project_templates/ # Project scaffolds (console, web, api, ai)
├── tests/             # Test suite (942+ tests)
├── vscode-extension/  # VS Code extension
├── tools/             # Project wizard, LSP server, toolchain
└── docs/              # Documentation
```

## Key Design Decisions

1. **AST as frozen dataclasses**: Immutable, hashable AST nodes with `children()` for traversal.
2. **Type annotations as strings**: `var_type`, `return_type`, `param_types` store type names as `str | None` to avoid circular dependencies.
3. **Two compiler pipelines**: The Phase 6 pipeline uses regex-based parsing; the formal pipeline uses the AST walker. Both co-exist.
4. **Struct instances as dicts**: Panther struct instances are Python dicts with `__type` key.
5. **Security-native**: All modules have safe defaults, no hardcoded credentials, prompt injection detection, audit logging.

## Dependencies

PantherLang has zero runtime Python dependencies for core functionality. Optional dependencies:
- `openai`, `anthropic`, `google-generativeai`, `requests` for AI providers
- `requests` for web HTTP client
- `sqlite3` (stdlib) for database ORM
