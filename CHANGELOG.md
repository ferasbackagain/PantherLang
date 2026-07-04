# PantherLang Changelog

## 1.1.5 (2026-07-04) — Public Release

### Added
- Complete Panther Academy Lessons 01-10 (concepts → deployment)
- Complete Panther Book (12 chapters, language reference, standard library, web, AI, CLI, packaging)
- Complete Cookbook (50+ verified examples across all domains)
- AI Knowledge Pack: docs/ai/, llms.txt, llms-full.txt for LLM context
- Engineering evidence packages for audit trail (10+ reports)
- VS Code Extension v1.1.5 with debug adapter v1.1.5
- Cross-platform installers: Linux (install.sh), Windows (install.ps1, install.bat), macOS

### Changed
- Unified product version to 1.1.5 across all components (core, CLI, compiler, VS Code extension, debug adapter)
- Release channel upgraded from "developer" to "stable"
- Full regression: 1039 tests passing, 11/11 examples passing
- Build produces pantherlang-1.1.5.tar.gz and pantherlang-1.1.5-py3-none-any.whl
- Git cleanliness: cache/backup artifacts moved to .gitignore, source only

### Fixed
- Comparison semantics: strict equality with descriptive errors (PDL-005)
- Expression parser: brace parsing, comparison precedence, AST export
- Web runtime: non-serve output, example preview blocks, contract cleanup
- Stdlib S1-S6: JSON tests, release contract compliance
- All 1039 tests passing with zero failures

---

## 1.0.0 (2026-07-01) — Developer Edition

### Added
- Complete compiler pipeline: lexer, parser, AST, semantic analysis, type checker
- Full runtime engine with variable environment, expression evaluation, statement execution
- Standard library: string manipulation, math, JSON, time, type conversion, crypto
- Type system: primitives, type checker, inference, annotations
- Package manager: dependency resolution, version constraints, lock files
- Web platform: HTTP server, router, request handlers, security middleware
- Database ORM: SQLite engine, query builder, migrations, model definitions
- AI platform: OpenAI, Anthropic, Gemini, Ollama, OpenRouter providers
- AI agents: tool calling, RAG engine, vector store, secure agent
- Security-native: sandbox, secret detection, prompt injection detection, audit logging
- CLI: run, build, check, new, doctor, fmt, package commands
- VS Code extension: syntax highlighting, project wizard, debug adapter, commands
- Cross-platform: Linux, Windows, macOS support via pathlib
- 942+ passing tests with full regression

### Changed
- Unified product version to 1.0.0
- Consolidated packaging for PyPI distribution
- Standardized CLI entry points

### Fixed
- Cross-platform path handling
- API key mock mode for testing without credentials
- Import caching conflicts in test collection
