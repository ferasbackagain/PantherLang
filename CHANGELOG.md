# PantherLang Changelog

## 1.1.8 (2026-07-12) — Standard Library 2.0 and Package Architecture

### Added
- Panther package imports with `import panther.<name> as alias` syntax
- Standard Library 2.0: 25 organized `panther.*` packages with public APIs
- New `panther.serialization` package (JSON, YAML, TOML, MessagePack, CBOR, Base64, Hex, CSV)
- Package capability classifications: VERIFIED_EXECUTABLE, PANTHER_IMPLEMENTED, PYTHON_BOOTSTRAP_BACKED, API_SHAPE_ONLY, PARTIAL
- Verified multi-package example: imports 6 packages, passes `panther check` and `panther run`
- New package/runtime regression tests for import resolution and member-call evaluation
- Architecture honesty documentation (ARCHITECTURE_STATUS.md)
- Package maturity index (PACKAGE_MATURITY.md) and API index (PACKAGE_INDEX.md)
- Quick start guide with working examples (QUICK_START.md)

### Improved
- Import parsing and namespace resolution
- Package member-call evaluation semantics
- Semantic package registration at load time
- Function-literal parameter handling and return propagation
- Array/dictionary index assignment
- Short-circuit Boolean evaluation
- Runtime error propagation through control-flow bodies
- Package naming consistency across all 25 packages
- Standard-library loading order and Host ABI registration

### Fixed
- Duplicate flat built-in registrations causing shadowing
- `array_push` return contract (now returns new length)
- CLI parsing structure for subcommand handling
- Time naming conflicts between `time` package and built-ins
- Package alias semantic collisions in nested scopes
- Runtime errors swallowed inside `if`/`while`/`for` bodies

### Verification
- README showcase example passes `panther check` and `panther run`
- VSIX builds successfully: `pantherlang-official-1.1.8.vsix`
- Package metadata aligned to 1.1.8 across all components
- Zero production secrets in repository
- Generated artifacts excluded from git
- Full regression: 1330 tests passing, 0 failed, 0 errors

### Known Limitations
- `panther.web`: HTTP server runs via `--serve`; no TLS, limited middleware, no production deployment tooling
- `panther.async` / `panther.concurrent`: Primitives delegate to Python runtime; no true preemptive multitasking in Panther
- `panther.ai`: External providers (OpenAI, Anthropic, Google, Ollama) return structured errors; only mock provider works without credentials
- `panther.cloud` / `panther.container`: Data-structure APIs only; no live AWS/GCP/Azure/Docker daemon integration
- `panther.process`: Current-process introspection works; subprocess execution not implemented
- Compiler not fully self-hosted; Python bootstrap remains for parser, type checker, and runtime
- Distributable artifacts include Python runtime; not native binaries

---

## 1.1.6 (2026-07-04) — Audit-Corrected Release

### Added
- Version reconciliation: all components now report 1.1.6 (core, CLI, compiler, VS Code extension, debug adapter)
- Git cleanliness: backup/cache artifacts removed from index, .gitignore updated
- Academy truth audit: docs/academy/ACADEMY_RELEASE_STATUS_v1_1_5.md (Lessons 01-05 verified complete, 06-10 in development)
- Book truth audit: docs/book/BOOK_RELEASE_STATUS_v1_1_5.md (15 chapters, 12 substantive)
- Cookbook truth audit: docs/cookbook/COOKBOOK_RELEASE_STATUS_v1_1_5.md (11 verified examples, roadmap to 500)
- AI Knowledge Pack unification: docs/ai/README.md, docs/ai/AI_KNOWLEDGE_PACK_v1_1_5.md, llms.txt, llms-full.txt
- Engineering manifests: FINAL_RELEASE_SUMMARY_FOR_FERAS.md, PUBLIC_LAUNCH_CHECKLIST.md, PANTHER_ACADEMY_LAUNCH_PLAN.md, INSTALLATION_GUIDE_LINUX_WINDOWS.md

### Changed
- Corrected aspirational claims in documentation to match verified reality
- Academy: Lessons 01-05 complete (Lesson 01 directory created), Lessons 06-10 marked "In Development"
- Cookbook: Documented 11 verified examples, removed "500 examples" claim
- Book: Documented 15 chapters (12 substantive), chapters 16-18 noted as planned
- All version references updated to 1.1.6

### Fixed
- Version drift between core (1.1.5) and VS Code extension (1.1.5) now unified at 1.1.6
- Git index pollution from .panther/backups/, .phase_backups/, .panther/p3_atomic_replacement/ removed

---

## 1.1.5 (2026-07-04) — Public Release (Aspirational — See 1.1.6 Corrections)

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
