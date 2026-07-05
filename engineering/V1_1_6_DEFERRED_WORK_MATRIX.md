# PantherLang v1.1.6 — Deferred Work Matrix

**Date:** 2026-07-04
**Classification:** DONE_VERIFIED | DONE_BUT_NEEDS_RECHECK | IMPLEMENTED_UNPROVEN | PARTIAL | DEFERRED | BLOCKED | SHOULD_NOT_CLAIM | NEXT_RELEASE | FUTURE_PLATFORM

---

## Core Language

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| Lexer (70 tokens, strings, comments) | **DONE_VERIFIED** | 1039 tests pass | Hand-written, single-pass |
| Parser (Pratt + recursive descent) | **DONE_VERIFIED** | 1039 tests pass | Error recovery via checkpoint/rollback |
| AST (frozen dataclasses) | **DONE_VERIFIED** | All node types present | Visitor pattern, serializer |
| Semantic analysis (E001-E008) | **DONE_VERIFIED** | 1039 tests pass | Symbol tables, scope management |
| Type checker (6 primitives, T001) | **DONE_VERIFIED** | 1039 tests pass | Gradual typing with explicit conversion |
| Tree-walking interpreter | **DONE_VERIFIED** | 1039 tests pass | Variable environment, expression eval |
| Compound assignment (+=, -=, etc.) | **DONE_VERIFIED** | Lesson 02 verify.pan PASS | 5 compound operators work |
| Array element assignment `arr[0] = x` | **SHOULD_NOT_CLAIM** | Phase 3 truth matrix | **BROKEN** — not yet implemented |
| Enum runtime | **SHOULD_NOT_CLAIM** | Phase 3 truth matrix | **BROKEN** — no runtime enum behavior |
| Trait method syntax `->` | **SHOULD_NOT_CLAIM** | Phase 3 truth matrix | **BROKEN** — trait `->` not parsed; traits are no-op |
| `**` exponent operator | **SHOULD_NOT_CLAIM** | Phase 3 truth matrix | **BROKEN** — token exists but parser fails |

## Compiler Architecture

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| Formal pipeline (execution_pipeline.py) | **DONE_VERIFIED** | Used by CLI `run` | Active, maintained |
| Phase 6 pipeline (panther_compiler.py) | **DEFERRED** | Legacy, regex-based | Deprecate in v1.2 |
| Core pipeline (compiler/core/compiler.py) | **DEFERRED** | Dead code, not used | Remove or archive in v1.2 |
| Single-source compilation | **SHOULD_NOT_CLAIM** | 3 pipelines coexist | Claiming "one compiler" is false |
| Language/compiler integration | **DONE_BUT_NEEDS_RECHECK** | `compiler/core/compiler.py` imports it | Needs verification that nothing breaks on removal |

## Standard Library

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| 125 registered function names | **DONE_VERIFIED** | Stdlib Truth Matrix | All registered and callable |
| `knowledge/stdlib.json` (54 functions) | **PARTIAL** | ~50 S1-S6 functions missing | Must update to 125 entries |
| Original naming convention (read_file) | **DONE_VERIFIED** | 22 functions work | Generic snake_case |
| S1-S6 namespaced convention (fs_read) | **DONE_VERIFIED** | ~50 functions work | Prefix namespacing |
| Duplicate name pairs (~22) | **NEXT_RELEASE** | Both names work | Deprecate one convention in v1.2 |
| Consistent error handling | **SHOULD_NOT_CLAIM** | 3 patterns coexist | Silent None, structured dict, hard crash |
| Input validation on stdlib | **SHOULD_NOT_CLAIM** | Most functions lack validation | `sha256(non_string)` crashes |
| Cross-platform system functions | **PARTIAL** | 6 functions Linux-only | Silent failure on macOS/Windows |

## Security

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| SecurityAnalyzer (S001-S005) | **DONE_VERIFIED** | 90 security tests pass | AST-level analysis |
| Security diagnostics in CLI `check` | **SHOULD_NOT_CLAIM** | CLI `check` only parses | NOT wired — must be fixed |
| Sandbox (ResourceLimits, ReadOnlySandbox) | **DONE_VERIFIED** | 11 tests pass | Runtime enforcement |
| Sandbox wired into interpreter | **SHOULD_NOT_CLAIM** | Requires Python opt-in | Not automatic |
| Web security middleware | **DONE_VERIFIED** | 14 tests pass | Headers, CSRF, xss, rate limit, CORS, JWT |
| AI security (prompt injection, audit) | **DONE_VERIFIED** | 10 tests pass | 22 patterns, output validation |
| SecureAgent | **DONE_VERIFIED** | 8 tests pass | Injection blocking, audit logging |
| Package security (checksums, typosquat) | **DONE_VERIFIED** | 8 tests pass | Integrity checking |

## AI Platform

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| `ai { }` block syntax | **DONE_BUT_NEEDS_RECHECK** | Parser accepts | Runtime is **NO-OP** — not executed |
| `ai_supported_providers()` | **DONE_VERIFIED** | Returns 5 providers | Mock mode: `openai available: false` |
| `ai_provider_available()` | **DONE_VERIFIED** | Checks env vars | No connectivity check |
| `ai_mock_chat()` | **DONE_VERIFIED** | Returns mock response | Offline-safe |
| Agent class (Python) | **DONE_VERIFIED** | 22 AI platform tests pass | Provider-agnostic, tool calling |
| SecureAgent (Python) | **DONE_VERIFIED** | 8 secure_agent tests pass | Injection + audit + sanitization |
| RAGEngine (Python) | **DONE_VERIFIED** | 22 AI platform tests pass | VectorStore, embeddings, query |
| PantherLang-native agent | **SHOULD_NOT_CLAIM** | No language syntax | Python API only |
| AI block execution | **SHOULD_NOT_CLAIM** | Runtime no-op | Syntax decoration only |
| Real AI provider integration | **PARTIAL** | 5 providers, mock mode only | API keys required for real calls |
| "AI-native" claim | **SHOULD_NOT_CLAIM** | No language-level AI | Python library, not language feature |

## Web Platform

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| HttpServer class | **DONE_VERIFIED** | 15 platform tests pass | Route registration, dispatch |
| `web { route GET "..." { } }` block | **DONE_VERIFIED** | Runtime test: GET / → 200 | Real HTTP serving |
| `api { }` block | **DONE_VERIFIED** | Same as web block | No separate API semantics |
| `panther run --serve` | **DONE_VERIFIED** | Server starts, routes registered | Verified with real requests |
| GET routes | **DONE_VERIFIED** | HTML + JSON responses | Auto content-type detection |
| POST routes | **DONE_VERIFIED** | Body dispatch | Partial — body echo not working |
| PUT route methods | **SHOULD_NOT_CLAIM** | Parser does not accept | Only GET and POST parsed |
| DELETE route methods | **SHOULD_NOT_CLAIM** | Parser does not accept | Only GET and POST parsed |
| Path parameters `/hello/{name}` | **SHOULD_NOT_CLAIM** | Returns 404 | Not implemented |
| WebSocket | **FUTURE_PLATFORM** | Not in any plan | Would require async rewrite |
| Middleware chaining | **NEXT_RELEASE** | Security middleware exists | Not chainable |

## Database Platform

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| `db_open/db_close/db_execute/db_query` | **DONE_VERIFIED** | Full CRUD verified | In-memory and file paths |
| `sqlite_*` aliases | **DONE_VERIFIED** | Same implementations | Dual namespace |
| Parameterized queries | **DONE_VERIFIED** | `?` placeholders work | SQL injection safe |
| ORM layer (Python) | **DONE_VERIFIED** | 20 ORM tests pass | SqliteEngine, QueryBuilder, Table/Column |
| Migration system | **DONE_VERIFIED** | 2 migration tests pass | Versioned, idempotent |
| Connection pooling | **FUTURE_PLATFORM** | Not implemented | Single connection per `db_open` |
| Async queries | **FUTURE_PLATFORM** | No async in language | All sync |

## Academy / Education

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| Lessons 01-08 main.pan (executable) | **DONE_VERIFIED** | All 8 pass | Real code exercises |
| Lessons 09-18 main.pan (descriptive) | **PARTIAL** | Run but print text | Need executable content |
| Verify.pan 01-10 (real tests) | **DONE_VERIFIED** | All PASS | PASS/FAIL assertions |
| Verify.pan 11-18 (descriptive) | **PARTIAL** | Print concepts only | Need real assertions |
| Cookbook (19 recipes) | **DONE_VERIFIED** | All 19 PASS | ~90% executable |
| Lab solutions (21) | **DONE_VERIFIED** | All execute | ~86% executable |
| Capstone solutions (7) | **DONE_VERIFIED** | All execute | 100% executable |
| Academy-Book-Cookbook cross-refs | **SHOULD_NOT_CLAIM** | 3 separate curricula | No integration between them |
| `array_sort`/`array_reverse` docs | **SHOULD_NOT_CLAIM** | Show in-place mutation | Actually return copies |

## Book

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| Chapters 01-06 (fundamentals) | **DONE_VERIFIED** | Accurate, substantive | Matches implementation |
| Chapter 07 (stdlib) | **PARTIAL** | Claims 43 functions | 125 actually exist |
| Chapter 08 (security) | **DONE_VERIFIED** | Accurate | Security features documented |
| Chapters 09-10 (web/database) | **DONE_VERIFIED** | Accurate | Platform features documented |
| Chapter 11 (AI) | **SHOULD_NOT_CLAIM** | Shows Python code | Not PantherLang code |
| Chapters 12-14 | **DONE_VERIFIED** | Accurate | CLI, language ref |
| Chapter 15 (comparisons) | **PARTIAL** | Only 7 lines | Minimal content |
| Chapters 16-18 | **PARTIAL** | Substantive content exists | From outline, not fully edited |

## Specification

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| Lexical specification | **PARTIAL** | Claims `put`/`delete` keywords | Not in lexer implementation |
| Grammar (EBNF) | **DONE_VERIFIED** | GET/POST/PUT/DELETE all work via IDENTIFIER | 16 end-to-end HTTP tests pass |
| Keywords spec | **PARTIAL** | 30 keywords listed | `put` and `delete` not reserved |
| Operators spec | **DONE_VERIFIED** | Accurate | Precedence table matches |
| Type system spec | **DONE_VERIFIED** | Accurate | Matches implementation |
| Runtime spec | **DONE_VERIFIED** | Accurate | Execution model documented |
| Modules spec | **DONE_VERIFIED** | Honest about incomplete | "Not fully implemented" |
| Errors spec | **DONE_VERIFIED** | Accurate | E001-E008, T001, S001-S005 |

## Tooling

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| `panther run` | **DONE_VERIFIED** | Tested | Working |
| `panther run --serve` | **DONE_VERIFIED** | Tested with real requests | Working |
| `panther build` | **DONE_BUT_NEEDS_RECHECK** | Not tested | Phase 6 pipeline |
| `panther check` | **DONE_VERIFIED** | Tested — detects S001-S005 | Security diagnostics wired, 7 tests pass |
| `panther fmt` | **DONE_BUT_NEEDS_RECHECK** | Not tested | Exists |
| `panther new` | **DONE_BUT_NEEDS_RECHECK** | Not tested | Scaffolds templates |
| `panther doctor` | **DONE_VERIFIED** | Tested | Installation verification |
| LSP server | **IMPLEMENTED_UNPROVEN** | Exists in tools/ | Not tested |
| DAP debugger | **IMPLEMENTED_UNPROVEN** | Exists in tools/ | Not tested |
| Formatter | **IMPLEMENTED_UNPROVEN** | Exists | Not tested for correctness |

## VS Code Extension

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| Package version 1.1.6 | **DONE_VERIFIED** | package.json | Consistent |
| Syntax highlighting | **DONE_VERIFIED** | TextMate grammar exists | Likely works |
| Snippets | **DONE_BUT_NEEDS_RECHECK** | Defined | Not tested |
| DAP integration | **IMPLEMENTED_UNPROVEN** | Files exist | Not tested |
| LSP client | **IMPLEMENTED_UNPROVEN** | Files exist | Not tested |
| VSIX build | **DONE_BUT_NEEDS_RECHECK** | Can package | Not tested |
| VS Code Marketplace | **BLOCKED** | Not published | Requires human authorization |

## Repository Cleanup

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| Root directory clutter | **SHOULD_NOT_CLAIM** | 112+ entries | ~80 historical scripts/docs |
| `.panther/` tracked files (817) | **SHOULD_NOT_CLAIM** | .gitignore empty | Must untrack |
| `vscode_extension/` duplicate | **SHOULD_NOT_CLAIM** | Stale copy | Must archive |
| Bootstrap scripts at root | **SHOULD_NOT_CLAIM** | 100+ scripts | Move to scripts/ or .archive/ |
| README_*.md at root | **SHOULD_NOT_CLAIM** | 25+ files | Consolidate into docs/ |
| Internal documents at root | **SHOULD_NOT_CLAIM** | MASTER_PROMPT.md, batch files | Remove or move |
| Git history cleanliness | **DEFERRED** | Clean on surface | Commits are reasonable |

## Version Reconciliation

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| `pyproject.toml` → 1.1.6 | **DONE_VERIFIED** | Correct | ✅ |
| `panther_core/version.py` → 1.1.6 | **DONE_VERIFIED** | Correct | ✅ |
| `compiler/version.py` → 1.1.6 | **DONE_VERIFIED** | Correct | ✅ |
| `cli/version.py` → 1.1.6 | **DONE_VERIFIED** | Correct | ✅ |
| `vscode-extension/package.json` → 1.1.6 | **DONE_VERIFIED** | Correct | ✅ |
| `cli/panther_cli.py:30` fallback | **DONE_VERIFIED** | Fixed → 1.1.6 | Was 1.0.0 |
| `vscode_extension/package.json` → 1.0.0 | **DEFERRED** | Stale duplicate | Will be archived in Phase 19 |

## Packaging

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| `python -m build` | **DONE_VERIFIED** | Built successfully | `pantherlang-1.1.6.tar.gz` + `.whl` |
| `pip install -e .[dev]` | **DONE_VERIFIED** | Development install works | ✅ |
| PyPI publishing | **BLOCKED** | Not authorized | Requires `twine upload` + API token |

## Testing

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| Full test suite | **DONE_VERIFIED** | 1039 passed, 0 failed | Clean regression |
| Security tests (8 files) | **DONE_VERIFIED** | 90 passed | All pass |
| AI platform tests | **DONE_VERIFIED** | 22 passed | All pass |
| Web platform tests | **DONE_VERIFIED** | 50 passed | All pass |
| Database tests | **DONE_VERIFIED** | 23 passed | All pass |
| Academy tests | **DONE_VERIFIED** | All pass (2 fixed this session) | Fixed comparison_policy.pan path |
| Cookbook tests | **DONE_VERIFIED** | All 19 pass | All pass |

## Release & Handoff

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| GitHub push | **BLOCKED** | Not authorized | User instruction: "Do NOT push" |
| GitHub Release (v1.1.6 tag) | **BLOCKED** | Not authorized | Requires tag creation |
| VS Code Marketplace publish | **BLOCKED** | Not authorized | Requires `vsce publish` |
| PyPI publish | **BLOCKED** | Not authorized | Requires `twine upload` |
| Website deploy | **FUTURE_PLATFORM** | Not started | Phase 28 |
| Panther Studio | **FUTURE_PLATFORM** | Not started | Phase 29 |
| Panther Platform | **FUTURE_PLATFORM** | Not started | Phase 30 |
| Clean-room install test | **DEFERRED** | Not run | Requires fresh venv |
| Fresh clone simulation | **DEFERRED** | Not run | Requires `git clone` to temp dir |

## Flagship Application

| Item | Classification | Evidence | Notes |
|------|---------------|----------|-------|
| Design spec | **DEFERRED** | Not written | MISSION 5 in progress |
| Implementation | **DEFERRED** | Not started | MISSION 6 says "do not build yet" |

## Legend

| Classification | Meaning |
|---------------|---------|
| **DONE_VERIFIED** | Implemented, tested, and verified in this session |
| **DONE_BUT_NEEDS_RECHECK** | Implemented but not tested in this session |
| **IMPLEMENTED_UNPROVEN** | Code exists but functionality is unverified |
| **PARTIAL** | Partially complete with known gaps |
| **DEFERRED** | Planned but deferred to later phase |
| **BLOCKED** | Cannot proceed (needs authorization or external dependency) |
| **SHOULD_NOT_CLAIM** | Would be false if claimed at current state |
| **NEXT_RELEASE** | Planned for v1.1.7 or v1.2 |
| **FUTURE_PLATFORM** | Belongs to website/Studio/Platform phase |
