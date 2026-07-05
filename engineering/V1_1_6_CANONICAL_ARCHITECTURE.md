# PantherLang v1.1.6 — Canonical Architecture

**Date:** 2026-07-04

---

## Production Compiler Pipeline

The canonical compiler pipeline flows through `compiler/`:

```
Source Code
  → compiler/lexer/          — PantherLexer, tokens
  → compiler/parser/         — Pratt expression parser + recursive descent
  → compiler/ast/            — Frozen dataclass nodes
  → compiler/semantic/       — Symbol table, scope, diagnostics (E001–E008)
  → compiler/types/          — Type checker, inference (T001)
  → compiler/runtime/        — Tree-walking interpreter
  → Output / Side Effects
```

**Additional compiler sub-engines:**
- `compiler/stdlib/` — Stdlib handler (stdlib_engine.py, functions.py)
- `compiler/web/` — Web server (server.py, security.py)
- `compiler/ai/` — AI providers (providers.py, agents.py, secure_agent.py, rag.py)
- `compiler/database/` — SQLite ORM (orm.py)
- `compiler/security/` — Security analyzer (analyzer.py, sandbox.py, ai_security.py, web_security.py)
- `compiler/expressions/` — Expression engine
- `compiler/control_flow/` — Control flow engine
- `compiler/loops/` — Loop engine
- `compiler/functions/` — Function engine
- `compiler/structs/` — Struct engine
- `compiler/modules/` — Module engine
- `compiler/optimization/` — Optimizer
- `compiler/incremental/` — Incremental compilation
- `compiler/pipeline/` — Phase 6 pipeline (legacy regex-based)
- `compiler/runtime_bridge/` — Runtime bridge
- `compiler/runtime_contract/` — Runtime contract
- `compiler/core/` — Core compiler (imports language.compiler.core)

## Dependencies on `language/`

**One file** in the canonical compiler imports from `language/`:
- `compiler/core/compiler.py` → `language.compiler.core.ir_builder`, `language.compiler.core.codegen`

These provide IR construction and Python code generation. The `language/` tree is **not a duplicate** — it is an **integrated component** providing codegen capabilities.

## CLI Entry Point

```
cli/panther_cli.py      — Primary CLI (333 lines)
cli/panther_cli_v2.py   — Secondary CLI (alternative implementation)
cli/version.py          — Delegates to panther_core.version
```

## Runtime

**Production runtime:** `compiler/runtime/`
**Supplemental runtime:** `runtime/` — Used only by Phase 7 tests, not by production CLI.

## VS Code Extension

**Canonical:** `vscode-extension/` (version 1.1.6)
**Stale copy:** `vscode_extension/` (version 1.0.0) — Not used, no activationEvents for Panther files.

## Debug Adapter Protocol (DAP)

**Canonical:** `debug_adapter/` — Active DAP implementation
**Stale variants:** `debug_adapter_bridge/`, `debug_adapter_rebuilt/`, `debug_adapter_legacy_P3_20260629_111133/`

## Tooling

**Canonical:** `tools/` — Contains lsp, debugger, formatter, docgen, project_wizard, project_runner
**Stale:** `toolchain/` — Not imported by canonical code

## Testing

**Canonical:** `tests/` — 48 subdirectories, 1039+ tests

Key test areas:
- `tests/academy/` — Academy lesson tests
- `tests/conformance/` — Language conformance
- `tests/security/` — Security platform tests
- `tests/R1_product_unification/` — Version alignment
- `tests/R3_compiler_runtime/` — Compiler-runtime contract
- `tests/phase6_*/` — Phase 6 pipeline tests
- `tests/phase7_*/` — Phase 7 runtime tests
