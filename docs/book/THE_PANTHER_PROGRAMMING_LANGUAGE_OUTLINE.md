# The Panther Programming Language — Book Outline

**Edition:** 1.0 (Draft)

**Prerequisites:** Basic programming knowledge, Python 3.10+ installed.

**Examples used:** See `examples/` directory in the repository.

---

## Chapter 1: Getting Started

- What is PantherLang?
  - Modern, Secure, AI-Native, Cross-Platform
  - The Panther Ecosystem vision
- Installation
  - `pip install pantherlang`
  - Verify with `panther doctor`
- Your First Program
  - `panther new console hello`
  - `panther run src/main.panther`
- The `panther main { }` block
- Hello, World variations

**Verification:** All examples in this chapter must run with `panther run`.

---

## Chapter 2: Variables and Types

- Variable declaration with `let`
- Type inference
- Primitive types: int, float, string, bool, null
- Type annotations (`let x: int = 42`)
- Assignment and reassignment
- Compound assignment operators
- Constants vs variables

**Verification:** Type checker tests must pass. Examples in `examples/console_hello/`.

---

## Chapter 3: Expressions and Operators

- Arithmetic operators: `+ - * / % **`
- Comparison operators: `== != > < >= <=`
- Logical operators: `&& || !`
- Operator precedence
- String concatenation
- Type conversion functions: `int()`, `float()`, `string()`

**Verification:** Calculator example in `examples/calculator/` must pass.

---

## Chapter 4: Control Flow

- `if` / `elif` / `else`
- Conditional expressions
- `while` loops
- `for` loops with ranges
- `break` and `continue`
- Nested control flow

**Verification:** Control flow tests in test suite must pass.

---

## Chapter 5: Functions

- Function declaration with `fn`
- Parameters and arguments
- Return values
- Recursion
- Function scope
- Functions as values (planned)

**Verification:** Recursive factorial in calculator example must work.

---

## Chapter 6: Scope and Modules

- Block scope
- Global scope
- Nested scope and shadowing
- Module imports
- Module aliases

**Verification:** Scope tests and module tests must pass.

---

## Chapter 7: Data Structures

- Structs
- Enums
- Traits (interface-like)
- Struct field access
- Planned: arrays, dictionaries

**Verification:** Struct/enum/trait tests must pass.

---

## Chapter 8: Standard Library

- String operations (len, upper, lower, trim, contains, replace, split, join)
- Math functions (abs, max, min, pow, sqrt, floor, ceil, round, random)
- JSON encoding/decoding
- Time functions
- Type conversion
- Crypto functions (sha256, hmac, secure_token, secure_compare)
- Path sanitization

**Verification:** Stdlib tests in `tests/phase6_batch6_1/` must pass.

---

## Chapter 9: Security

- Security-native design principles
- Secret detection in source code
- Runtime sandbox (time, memory, file limits)
- Path traversal prevention
- HTML sanitization
- Prompt injection detection
- Audit logging
- Secure agent patterns

**Verification:** Security tests in `tests/security/` must pass.

---

## Chapter 10: Web Platform

- HTTP server foundation
- Route registration
- Security headers
- CORS
- CSRF protection
- Rate limiting
- Secure cookies
- JWT validation

**Verification:** Web platform tests in `tests/phase8_batch8_1/` must pass.

---

## Chapter 11: Database Platform

- SQLite integration
- Query builder
- ORM model definitions
- Migrations
- Column types and constraints

**Verification:** Database tests in `tests/phase9_batch9_1/` must pass.

---

## Chapter 12: AI Platform

- Provider abstraction
- OpenAI, Anthropic, Gemini, Ollama, OpenRouter
- Embeddings
- Agents and tool calling
- RAG engine
- Vector store
- Secure agent with injection detection
- Audit trails

**Verification:** AI tests in `tests/phase10_batch10_1/` must pass.

---

## Chapter 13: Package Management

- Project manifests (`panther.toml`)
- Dependency resolution
- Version constraints (`>=`, `^`, `~`, `*`, `latest`)
- Lock files
- Package integrity verification
- Typosquat detection

**Verification:** Package manager tests in `tests/phase7_batch7_1/` must pass.

---

## Chapter 14: CLI and Tooling

- `panther run`, `build`, `check`, `new`, `doctor`, `fmt`
- VS Code extension
- Debug adapter
- LSP server

**Verification:** CLI tests and VS Code extension tests must pass.

---

## Chapter 15: Cross-Platform Development

- Linux, Windows, macOS support
- pathlib conventions
- Installer scripts
- CI/CD workflows

**Verification:** Cross-platform toolchain tests must pass.

---

## Chapter 16: Language Reference

- Complete syntax reference
- Operator precedence table
- Standard library API reference
- Error codes reference
- Security diagnostic codes

---

## Chapter 17: Contributing

- Development setup
- Test suite
- Coding conventions
- PR workflow

---

## Chapter 18: The Panther Ecosystem

- PantherLang
- Panther Studio (planned IDE)
- PantherAI
- Panther Academy
- PantherHub
- Panther Cloud
- Panther Enterprise

---

## Writing Prerequisites

Before writing each chapter, the following must be verified:

| Chapter | Must Pass |
|---------|-----------|
| 1-3 | `panther run examples/console_hello/main.pan` |
| 3-5 | `panther run examples/calculator/calc.pan` |
| 8 | Stdlib tests (`tests/phase6_batch6_1/`) |
| 9 | Security tests (`tests/security/`) |
| 10 | Web tests (`tests/phase8_batch8_1/`) |
| 11 | Database tests (`tests/phase9_batch9_1/`) |
| 12 | AI tests (`tests/phase10_batch10_1/`) |
| 13 | Package manager tests (`tests/phase7_batch7_1/`) |
| 14 | Full regression (0 failures) |
| 15 | Cross-platform toolchain tests |
| All | Full regression: 0 failed, 0 errors |
