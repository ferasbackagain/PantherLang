# PantherLang Language-First Audit

## Current Ratio Estimate

| Category | Estimated % | Description |
|----------|-------------|-------------|
| Language core | 35% | Parser, AST, semantic analysis, type system, runtime |
| Standard library | 15% | String, math, JSON, time, crypto, path security |
| Security-native | 10% | Sandbox, secret detection, audit, injection detection |
| Web platform | 8% | HTTP server, routing, security headers |
| Database ORM | 5% | SQLite, query builder, migrations |
| AI platform | 10% | Providers, agents, RAG, vector store, secure agent |
| CLI & tooling | 7% | panther commands, build, check, fmt |
| VS Code extension | 5% | Syntax highlighting, debug adapter, wizard |
| Packaging & docs | 5% | PyPI, installers, README, guides |

**Language/runtime total: ~83%**
**Tooling/packaging total: ~17%**

Current assessment: **Language-first ratio is on target.**

## What Exists

### Parser ✓
- Complete PantherLang grammar
- Block/statement/expression parsing
- Program, web, api, ai, test entry types
- Error recovery with diagnostics

### AST ✓
- Frozen dataclass AST nodes
- Program, statements, expressions, literals
- Visitor pattern support
- Serializer

### Semantic Analysis ✓
- Symbol table
- Scope chains
- Name resolution
- Duplicate detection
- Error codes E001–E008

### Type System ✓
- Primitives: int, float, string, bool, null, any
- Type checker with inference
- Annotation parsing
- Compatibility rules
- Error code T001

### Runtime ✓
- Expression evaluator
- Statement executor
- Variable environment with scope chains
- Control flow: if/else, while, for, break, continue
- Functions with recursion
- Struct instances as dicts
- `execute_source()` entry point

## What Is Missing (Priority Order)

### High Priority

1. **Array/list literals** — Cannot create array values in PantherLang source.
   Currently arrays are only used in stdlib returns (json_decode, split).
   *Impact: Security audit example had to avoid arrays.*

2. **Dictionary/object literals** — Cannot create dict values in source.
   Struct instances are created via constructor syntax `Point(1, 2)`.
   *Impact: Web/API examples use print placeholders instead of JSON.*

3. **String iteration** — Cannot iterate over characters.
   `len(text)` works but `text[i]` string indexing is not supported.

4. **Native web/API/AI runtime execution** — Template concepts (`panther api {}`,
   `panther web {}`, `panther ai {}`) define entry types but the runtime
   only executes `panther main {}`. The `compiler.web.server.HttpServer`
   Python class works but is not callable from PantherLang source.

### Medium Priority

5. **Error messages** — Parse errors show internal diagnostic objects rather
   than user-friendly messages. Source snippets are missing.

6. **File I/O** — No `read_file`, `write_file` in stdlib. Filesystem access
   only through Python bridge.

7. **Module resolution** — Import statements exist in AST but full module
   resolution from `panther.toml` manifest is not implemented.

8. **Formatted output** — `print` only appends to output list. No formatted
   string support (`printf`-style).

9. **Type enforcement at runtime** — Type annotations are parsed and checked
   by the semantic analyzer but not enforced during execution.

### Low Priority

10. **Async/await** — No async runtime
11. **Generics** — Type system doesn't support generic types
12. **Pattern matching** — No match expressions
13. **Iterator protocol** — No for..in over custom types
14. **Error handling** — No try/catch mechanism

## Risks

- **Parser brittleness**: Some syntax errors produce confusing cascading errors
- **Runtime coverage**: Many AST node types create struct/enum instances but
  the runtime doesn't execute all of them (traits, enums as values)
- **Array gap**: The lack of array literals is the biggest gap for real programs
- **Template vs parser mismatch**: Project templates use `panther api/ai/web {}`
  but parser's runtime only handles `panther main {}`

## Recommended Next Engineering Batches

1. **Batch 11.1**: Array and dictionary literals in runtime
   - Add `ArrayLiteral`/`ObjectLiteral` eval to ExpressionEvaluator
   - Support `len()` on arrays
   - Support indexing with `arr[i]`
   - Update stdlib functions to return proper types

2. **Batch 11.2**: Web/API/AI entry types in runtime
   - Add `WebBlock`, `ApiBlock`, `AiBlock` handling to StatementExecutor
   - Bridge to `compiler.web.server.HttpServer` and `compiler.ai` providers

3. **Batch 11.3**: User-friendly error messages
   - Format parse errors with source snippets and caret indicators
   - Color output for terminal

4. **Batch 11.4**: String indexing and iteration
   - `str[i]` for character access
   - `for c in str` iteration

5. **Batch 11.5**: File I/O stdlib functions
   - `read_file(path)`, `write_file(path, content)`
   - With path sanitization security checks
