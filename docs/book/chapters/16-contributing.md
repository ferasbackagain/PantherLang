# Chapter 16: Contributing to PantherLang

## Getting Started

PantherLang is an open-source project and welcomes contributions from the community. This chapter covers how to set up a development environment, the contribution workflow, and areas where help is needed.

## Development Setup

### Prerequisites
- Python 3.10+
- Git
- Node.js 18+ (for VS Code extension)
- npm/pnpm (for VS Code extension)

### Installation

```bash
# 1. Fork the repository on GitHub
# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/PantherLang.git
cd PantherLang

# 3. Install in development mode
pip install -e ".[dev]"

# 4. Verify installation
python -m cli.panther_cli doctor
python -m pytest
```

### VS Code Extension Development

```bash
cd vscode-extension
npm install
npm run compile
# Press F5 to launch extension development host
```

## Code Style and Quality

### Formatting
```bash
# Format a file
python -m cli.panther_cli fmt main.pan

# Format entire project (if tool exists)
python -m ruff format .
```

### Linting
```bash
# Check for issues
python -m ruff check .

# Auto-fix where possible
python -m ruff check --fix .
```

### Type Checking
```bash
# Run mypy on compiler
python -m mypy compiler/
```

### Pre-commit Hooks
```bash
# Install pre-commit
pip install pre-commit
pre-commit install
```

## Testing

### Run All Tests
```bash
python -m pytest
```

### Run Specific Test Suites
```bash
# Academy tests
python -m pytest tests/academy/ -v

# Security tests
python -m pytest tests/security/ -v

# Web platform tests
python -m pytest tests/ -k "web" -v

# Conformance tests
python -m pytest tests/conformance/ -v
```

### Test Examples
```bash
bash scripts/run_examples.sh
```

## Pull Request Process

### 1. Create a Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes
- Follow existing code patterns
- Add tests for new functionality
- Update documentation as needed
- Run formatter and linter

### 3. Verify
```bash
# Full test suite
python -m pytest

# Check specific areas
python -m cli.panther_cli doctor
bash scripts/run_examples.sh
```

### 4. Commit with Clear Messages
```bash
git add .
git commit -m "feat: add new stdlib function for X

- Implement function in compiler/stdlib/functions.py
- Register in stdlib registry
- Add tests in tests/
- Update documentation"
```

### 5. Push and Create PR
```bash
git push origin feature/your-feature-name
# Open PR on GitHub with description
```

### PR Requirements
- [ ] All tests pass
- [ ] Code formatted (`panther fmt` / `ruff format`)
- [ ] No linting errors (`ruff check`)
- [ ] Type checking passes (`mypy`)
- [ ] Documentation updated
- [ ] Changelog entry added (if applicable)

## Areas for Contribution

### Compiler Core
- **Lexer** (`compiler/lexer/`): Tokenization, new operators
- **Parser** (`compiler/parser/`): Grammar extensions, error recovery
- **Semantic Analysis** (`compiler/semantic/`): Symbol resolution, diagnostics
- **Type System** (`compiler/types/`): Inference, checking, generics
- **Runtime** (`compiler/runtime/`): Execution, optimization

### Standard Library
- New functions in `compiler/stdlib/functions.py`
- Categories: String, Math, JSON, Time, Crypto, Security, Filesystem, HTTP, Regex, Collections, SQLite

### Security
- New diagnostics (S001-S005+)
- Sandbox improvements
- Secret detection patterns
- Path traversal prevention

### Web Platform
- `compiler/web/server.py`: HTTP server, routing
- `compiler/web/security/`: Middleware (CSP, CSRF, Rate Limiting, CORS)

### AI Platform
- `compiler/ai/agents.py`: Agent framework
- `compiler/ai/secure_agent.py`: Secure agent with injection detection
- `compiler/ai/rag.py`: RAG engine
- Provider integrations (OpenAI, Anthropic, Gemini, Ollama, OpenRouter)

### Database
- `compiler/database/orm.py`: ORM, Query Builder, Migrations
- SQLite stdlib functions

### Tools
- **Formatter** (`tools/formatter/`): Code formatting
- **LSP** (`tools/panther-lsp/`): Language Server Protocol
- **Debugger** (`tools/debugger/`): Debug Adapter Protocol
- **VS Code Extension** (`vscode-extension/`): IDE integration

### Documentation
- **Academy** (`docs/academy/`, `academy/`): Structured lessons
- **Book** (`docs/book/chapters/`): Language reference
- **Cookbook** (`docs/cookbook/`): Practical recipes
- **API Docs**: Docstrings, module docs

### Tests
- Unit tests in `tests/`
- Integration tests
- Conformance tests
- Academy verification tests
- Security tests

### Examples
- New runnable examples in `examples/`
- Academy lesson examples
- Cookbook recipes

## Reporting Issues

### Bug Reports
Include:
- PantherLang version (`python -m cli.panther_cli version`)
- Operating system
- Minimal reproduction code
- Expected vs actual behavior
- Error messages/stack traces

### Feature Requests
Include:
- Use case description
- Proposed syntax/API
- Alternatives considered
- Willingness to implement

### Security Vulnerabilities
Report privately via GitHub Security Advisories or email the maintainers.

## Community

- **GitHub Discussions**: Questions, ideas, showcases
- **Discord**: Real-time chat (link in README)
- **Study Groups**: Organized learning sessions
- **Mentoring**: Experienced contributors guide newcomers

## Code of Conduct

Be respectful, inclusive, and constructive. See `CODE_OF_CONDUCT.md` for details.

## License

By contributing, you agree that your contributions will be licensed under the project's license (MIT).