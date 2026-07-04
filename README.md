# PantherLang

**PantherLang** is the official programming language of the Panther Ecosystem — a secure, defensive, production-ready language with built-in support for web, database, AI, and package management.

## Quick Install

```bash
pip install pantherlang
```

## Quick Start

```bash
panther doctor
panther new console myapp
cd myapp
panther run src/main.panther
```

## Features

- **Compiler**: Lexer, parser, AST, semantic analysis, type checker with 5 error codes (E001–E008, T001)
- **Runtime**: Full execution engine with variable environment, scope chains, control flow, functions, recursion
- **Standard Library**: String manipulation, math, JSON, time, type conversion, crypto (SHA-256, HMAC, secure tokens)
- **Type System**: Int, float, string, bool, null, any — with type checker, inference, annotations
- **Package Manager**: Version constraints (`>=`, `^`, `~`, `*`, `latest`), lock files, integrity checks, typosquat detection
- **Web Platform**: HTTP server with routing, CORS, CSRF protection, rate limiting, security headers, JWT validation
- **Database ORM**: SQLite engine, query builder, migrations, column definitions with type safety
- **AI Platform**: OpenAI, Anthropic, Gemini, Ollama, OpenRouter providers — with prompt injection detection, audit logging, secure agents, RAG engine, vector store
- **Security-Native**: Secret detection, sandbox (time/memory/file limits), path traversal prevention, dangerous API warnings
- **VS Code Extension**: Syntax highlighting, project wizard, run/debug commands, debug adapter, AI agent guide

## CLI Commands

| Command | Description |
|---------|-------------|
| `panther run <file>` | Run a PantherLang source file |
| `panther build <file>` | Build a PantherLang source file |
| `panther check <file>` | Validate a PantherLang source file |
| `panther fmt <file>` | Format a PantherLang source file |
| `panther new <type> <name>` | Create a new project (console, web, api, ai) |
| `panther doctor` | Verify PantherLang installation |
| `panther version` | Show version information |

## Project Templates

```bash
panther new console myapp    # Console application
panther new web myapp        # Web application
panther new api myapp        # API application
panther new ai myapp         # AI application
```

## Security

PantherLang is built with security as a core design principle:

- No hardcoded API keys — all credentials from environment variables
- Prompt injection detection for AI agents
- Rate limiting and CSRF protection for web servers
- Sandbox with resource limits for untrusted code
- Path traversal prevention in file operations
- Secret detection in source code analysis
- Audit logging for AI tool calls

## Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [CLI Guide](docs/CLI_GUIDE.md)
- [Language Reference](docs/LANGUAGE_REFERENCE.md)
- [Security Guide](docs/SECURITY_GUIDE.md)
- [Developer Guide](docs/DEVELOPER_GUIDE.md)

## License

Copyright (c) Feras Khatib. All rights reserved.

## Support

- GitHub Issues: https://github.com/feras-khatib/pantherlang/issues
- Documentation: https://github.com/feras-khatib/pantherlang/docs
