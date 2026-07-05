# Chapter 17: The Panther Ecosystem

## Overview

PantherLang is more than a language—it's a complete ecosystem for building secure, AI-native applications. This chapter covers the tools, templates, integrations, and distribution channels that make up the PantherLang platform.

## Project Templates

Scaffold new projects instantly with the `panther new` command:

### Console Application
```bash
panther new console my_app
```
Creates:
```
my_app/
├── main.pan              # Entry point with panther main { }
├── panther.toml          # Project configuration
├── .vscode/
│   ├── launch.json       # Debug configuration
│   ├── settings.json     # Workspace settings
│   └── tasks.json        # Build tasks
├── tests/
│   └── test_main.pan     # Test template
└── README.md             # Project guide
```

### Web Application
```bash
panther new web my_web_app
```
Includes HTTP server setup, routing examples, security middleware.

### API Application
```bash
panther new api my_api
```
REST API structure with JSON endpoints, request validation.

### AI Application
```bash
panther new ai my_ai_app
```
AI provider integration, agent setup, RAG engine template.

### Template Structure
All templates include:
- `main.pan` — Proper entry point structure
- `panther.toml` — Project metadata and dependencies
- `.vscode/` — IDE integration (debug, tasks, settings)
- `tests/` — Test scaffolding
- `README.md` — Getting started guide

## Package Registry

PantherLang includes a package management system for dependency resolution and distribution.

### Local Packages
```toml
# panther.toml
[package]
name = "my_project"
version = "0.1.0"
description = "My PantherLang project"

[dependencies]
# Local path dependencies
utils = { path = "../utils" }

# Registry dependencies (when available)
# panther_web = "1.0.0"
```

### Registry Structure
```
registry/
├── index.json              # Package index
├── published/
│   └── package_name/
│       └── version/
│           └── pkg/
│               └── package.panther
└── registry_cli.py         # Registry management CLI
```

### Security
- Dependency vulnerability scanning
- Lock files for reproducible builds
- Signature verification (planned)

## VS Code Extension

The official VS Code extension provides first-class IDE support.

### Features
- **Syntax Highlighting**: `.panther` and `.pan` files
- **Code Snippets**:
  - `pn-main` → `panther main { }`
  - `pn-fn` → `fn name() { }`
  - `pn-let` → `let x = value;`
  - `pn-if` → `if condition { } elif { } else { }`
  - `pn-for` → `for i in 0..10 { }`
  - `pn-struct` → `struct Name { fields }`
  - `pn-route` → `route GET "/path" { }`
- **Debug Adapter**: Breakpoints, variables, call stack, watch expressions
- **LSP Integration**: Hover, completion, diagnostics, go-to-definition
- **Project Wizard**: Create new projects from templates

### Installation
```bash
# From repository
cd vscode-extension
npm install
npm run package
code --install-extension pantherlang-1.1.5.vsix

# Or from VS Code Marketplace (when published)
# Search "PantherLang"
```

## CI/CD Integration

Cross-platform automation scripts for all major platforms.

### Linux / macOS
```bash
# Run examples
bash scripts/run_examples.sh

# Full test suite
bash scripts/test.sh

# Build package
python -m build
```

### Windows PowerShell
```powershell
# Run examples
.\scripts\run_examples.ps1

# Run tests
python -m pytest
```

### Windows Command Prompt
```cmd
scripts\run_examples.bat
```

### GitHub Actions Example
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: pip install -e ".[dev]"
      - run: python -m pytest
      - run: bash scripts/run_examples.sh
```

## Documentation

Comprehensive documentation at `docs/`:

### Academy (`docs/academy/`, `academy/`)
Structured lessons from beginner to advanced:
- 18 progressive lessons
- Runnable examples
- Exercises and verification
- Labs and assessments

### Book (`docs/book/chapters/`)
Complete language reference:
- 18 chapters covering all features
- Implementation-backed examples
- Specification cross-references

### Cookbook (`docs/cookbook/`)
Practical recipes for common tasks:
- Verified working examples
- Problem → Solution format
- Cross-platform compatible

### Specification (`docs/specification/`)
Formal language specification (8 specs):
- Lexical structure
- Syntax grammar
- Type system
- Semantics
- Runtime behavior
- Standard library
- Security model
- Platform integrations

## Distribution Channels

### PyPI Package
```bash
# Install stable release
pip install pantherlang

# Install development version
pip install -e ".[dev]"
```

### Source Distribution
```bash
# Build
python -m build

# Output in dist/
# pantherlang-1.1.6.tar.gz
# pantherlang-1.1.6-py3-none-any.whl
```

### VS Code Marketplace
```bash
# Package extension
cd vscode-extension
npm run package
# Output: pantherlang-1.1.5.vsix

# Install locally
code --install-extension pantherlang- pantherlang-1.1.5.vsix

# Publish (maintainers only)
npx vsce publish
```

### Docker (Planned)
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY . .
RUN pip install -e ".[dev]"
ENTRYPOINT ["panther"]
```

## Community Resources

### Official Links
- **Repository**: https://github.com/ferasbackagain/PantherLang
- **Issues**: Bug reports, feature requests
- **Discussions**: Questions, ideas, showcases
- **Security**: Private vulnerability reporting

### Learning
- **Academy**: Structured lessons at `academy/`
- **Book**: Language reference at `docs/book/`
- **Cookbook**: Recipes at `docs/cookbook/`
- **Examples**: Runnable programs at `examples/`

### Social
- **Founder**: Feras Khatib
- **LinkedIn**: https://www.linkedin.com/in/feras-khatib-98a02220b
- **Discord**: Community server (link in README)

## Versioning and Releases

### Version Scheme
`MAJOR.MINOR.PATCH` following Semantic Versioning:
- MAJOR: Breaking changes
- MINOR: New features, backward compatible
- PATCH: Bug fixes, backward compatible

### Release Process
1. Update version in `panther_core/version.py`
2. Update `CHANGELOG.md`
3. Run full test suite
4. Build package: `python -m build`
5. Publish to PyPI: `twine upload dist/*`
6. Publish VS Code extension: `npx vsce publish`
7. Create GitHub release with artifacts

## Future Directions

### Planned Ecosystem Enhancements
- **Package Registry Server**: Centralized package hosting
- **Language Server**: Standalone LSP for any editor
- **Web Playground**: Browser-based REPL
- **Mobile Support**: React Native / Flutter integration
- **Cloud Deploy**: One-click deployment targets
- **Plugin System**: Third-party compiler extensions

### Community Goals
- Expand standard library
- More AI provider integrations
- Enhanced debugging experience
- Performance optimization
- Educational partnerships

---

The PantherLang ecosystem is designed to grow with its community. Whether you're building a simple CLI tool, a web API, an AI agent, or a secure defensive application, the ecosystem provides the templates, tools, and infrastructure to go from idea to production.