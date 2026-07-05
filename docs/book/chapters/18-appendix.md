# Chapter 18: Appendix

## Glossary

| Term | Definition |
|------|------------|
| **Abstract Syntax Tree (AST)** | Tree representation of source code used during compilation |
| **Block** | A `{ }` delimited section of code with its own scope |
| **CLI** | Command-line interface; the `panther` command |
| **Closure** | A function that captures variables from its enclosing scope |
| **Compound Assignment** | Operators like `+=`, `-=` that combine operation with assignment |
| **DAP** | Debug Adapter Protocol; VS Code's debugging protocol |
| **Diagnostic** | A compiler message indicating an error, warning, or information |
| **Expression** | Code that produces a value |
| **Function** | A named block of code that can be called with arguments |
| **Inference** | Automatic type deduction by the compiler |
| **Keyword** | A reserved word in the language with special meaning |
| **LSP** | Language Server Protocol; protocol for IDE features |
| **Literal** | A fixed value written in source code (e.g., `42`, `"hello"`) |
| **Loop** | A control structure that repeats execution |
| **ORM** | Object-Relational Mapping; database abstraction layer |
| **RAG** | Retrieval-Augmented Generation; AI pattern combining retrieval with generation |
| **Route** | A web endpoint mapping an HTTP method and path to a handler |
| **Scope** | The region of code where a variable or function is visible |
| **Stdlib** | Standard Library; built-in functions available without import |
| **Struct** | A user-defined data structure with named fields |
| **Trait** | A set of method signatures that types can implement |
| **Type Annotation** | Explicit type declaration (e.g., `let x: int = 5`) |
| **VSIX** | VS Code extension package format |

## Keyword Index

| Keyword | Category | Chapter | Lesson |
|---------|----------|---------|--------|
| `panther` | Block | 01 | 01 |
| `main` | Block | 01 | 01 |
| `web` | Block | 09 | 09 |
| `api` | Block | 09 | 09 |
| `ai` | Block | 11 | 11 |
| `test` | Block | 12 | 14 |
| `if` | Statement | 04 | 03 |
| `elif` | Statement | 04 | 03 |
| `else` | Statement | 04 | 03 |
| `while` | Statement | 04 | 03 |
| `for` | Statement | 04 | 03 |
| `loop` | Statement | 04 | 03 |
| `break` | Statement | 04 | 03 |
| `continue` | Statement | 04 | 03 |
| `fn` | Statement | 05 | 04 |
| `return` | Statement | 05 | 04 |
| `let` | Statement | 02 | 02 |
| `print` | Function | 02 | 01 |
| `route` | Statement | 09 | 09 |
| `struct` | Statement | 06 | 06 |
| `enum` | Statement | 14 | 06 |
| `trait` | Statement | 14 | 08 |
| `import` | Statement | 14 | 07 |
| `true` | Literal | 03 | 15 |
| `false` | Literal | 03 | 15 |
| `null` | Literal | 03 | 15 |

## Operator Index

| Operator | Category | Description | Chapter |
|----------|----------|-------------|---------|
| `+` | Arithmetic | Addition, string concatenation | 03 |
| `-` | Arithmetic | Subtraction, negation | 03 |
| `*` | Arithmetic | Multiplication | 03 |
| `/` | Arithmetic | Division | 03 |
| `%` | Arithmetic | Modulo (remainder) | 03 |
| `**` | Arithmetic | Exponentiation | 03 |
| `+=` | Compound | Add and assign | 02 |
| `-=` | Compound | Subtract and assign | 02 |
| `*=` | Compound | Multiply and assign | 02 |
| `/=` | Compound | Divide and assign | 02 |
| `%=` | Compound | Modulo and assign | 02 |
| `==` | Comparison | Equal to | 03 |
| `!=` | Comparison | Not equal to | 03 |
| `>` | Comparison | Greater than | 03 |
| `>=` | Comparison | Greater than or equal | 03 |
| `<` | Comparison | Less than | 03 |
| `<=` | Comparison | Less than or equal | 03 |
| `&&` | Logical | And | 03 |
| `\|\|` | Logical | Or | 03 |
| `!` | Logical | Not | 03 |
| `[ ]` | Index | Array/object access | 06 |
| `.` | Member | Struct field access | 06 |
| `->` | Member | Pointer-style member access | 14 |
| `..` | Range | Range in for loops | 04 |

## Standard Library Function Index

### String (11)
| Function | Signature | Description |
|----------|-----------|-------------|
| `len` | `len(s) -> int` | String length |
| `substring` | `substring(s, start[, end]) -> str` | Extract substring |
| `contains` | `contains(s, sub) -> bool` | Check substring presence |
| `starts_with` | `starts_with(s, prefix) -> bool` | Check prefix |
| `ends_with` | `ends_with(s, suffix) -> bool` | Check suffix |
| `upper` | `upper(s) -> str` | Convert to uppercase |
| `lower` | `lower(s) -> str` | Convert to lowercase |
| `trim` | `trim(s) -> str` | Remove whitespace |
| `replace` | `replace(s, old, new) -> str` | Replace occurrences |
| `split` | `split(s, sep) -> list` | Split string |
| `join` | `join(sep, items) -> str` | Join items with separator |

### Math (10)
| Function | Signature | Description |
|----------|-----------|-------------|
| `abs` | `abs(x) -> number` | Absolute value |
| `max` | `max(a, b) -> number` | Maximum of two values |
| `min` | `min(a, b) -> number` | Minimum of two values |
| `pow` | `pow(base, exp) -> number` | Exponentiation |
| `sqrt` | `sqrt(x) -> float` | Square root |
| `floor` | `floor(x) -> int` | Round down |
| `ceil` | `ceil(x) -> int` | Round up |
| `round` | `round(x) -> int` | Round to nearest |
| `random` | `random() -> float` | Random float [0, 1) |
| `randint` | `randint(min, max) -> int` | Random integer in range |

### JSON (2)
| Function | Signature | Description |
|----------|-----------|-------------|
| `json_encode` | `json_encode(value) -> str` | Encode to JSON |
| `json_decode` | `json_decode(str) -> any` | Decode from JSON |

### Time (2)
| Function | Signature | Description |
|----------|-----------|-------------|
| `time` | `time() -> float` | Unix timestamp |
| `sleep` | `sleep(seconds) -> none` | Sleep for duration |

### Type Conversion (3)
| Function | Signature | Description |
|----------|-----------|-------------|
| `int` | `int(x) -> int` | Convert to integer |
| `float` | `float(x) -> float` | Convert to float |
| `string` | `string(x) -> str` | Convert to string |

### Crypto (4)
| Function | Signature | Description |
|----------|-----------|-------------|
| `sha256` | `sha256(s) -> str` | SHA-256 hex hash |
| `hmac_sha256` | `hmac_sha256(key, msg) -> str` | HMAC-SHA256 |
| `secure_token` | `secure_token(bytes) -> str` | Random hex token |
| `secure_compare` | `secure_compare(a, b) -> bool` | Constant-time comparison |

### Security (2)
| Function | Signature | Description |
|----------|-----------|-------------|
| `sanitize_path` | `sanitize_path(base, path) -> str` | Prevent path traversal |
| `sanitize_html` | `sanitize_html(s) -> str` | Escape HTML entities |

### Filesystem (6)
| Function | Signature | Description |
|----------|-----------|-------------|
| `read_file` | `read_file(path) -> str` | Read file contents |
| `write_file` | `write_file(path, content) -> none` | Write file |
| `file_exists` | `file_exists(path) -> bool` | Check file exists |
| `mkdir` | `mkdir(path) -> none` | Create directory |
| `list_dir` | `list_dir(path) -> list` | List directory contents |
| `remove_file` | `remove_file(path) -> none` | Delete file |

### HTTP (2)
| Function | Signature | Description |
|----------|-----------|-------------|
| `http_get` | `http_get(url) -> str` | HTTP GET request |
| `http_post` | `http_post(url, body) -> str` | HTTP POST request |

### Regex (3)
| Function | Signature | Description |
|----------|-----------|-------------|
| `regex_match` | `regex_match(pattern, text) -> bool` | Test regex match |
| `regex_replace` | `regex_replace(pattern, replacement, text) -> str` | Regex replace |
| `regex_split` | `regex_split(pattern, text) -> list` | Regex split |

### Collections (4)
| Function | Signature | Description |
|----------|-----------|-------------|
| `array_push` | `array_push(arr, item) -> int` | Push item to array |
| `array_pop` | `array_pop(arr) -> any` | Pop item from array |
| `array_sort` | `array_sort(arr) -> list` | Return sorted array |
| `array_reverse` | `array_reverse(arr) -> list` | Return reversed array |

### SQLite (4)
| Function | Signature | Description |
|----------|-----------|-------------|
| `db_open` | `db_open(path) -> conn` | Open database connection |
| `db_close` | `db_close(conn) -> none` | Close connection |
| `db_execute` | `db_execute(conn, sql, params?) -> none` | Execute SQL statement |
| `db_query` | `db_query(conn, sql, params?) -> list` | Query database |

## Error Code Index

| Code | Severity | Description | Detection |
|------|----------|-------------|-----------|
| E001 | Error | `break` outside a loop | Semantic analysis |
| E002 | Error | `continue` outside a loop | Semantic analysis |
| E003 | Error | Duplicate function declaration | Semantic analysis |
| E005 | Error | Duplicate variable declaration | Semantic analysis |
| E006 | Error | Duplicate import | Semantic analysis |
| E007 | Error | Undefined variable referenced | Semantic analysis |
| E008 | Error | Undefined function/symbol | Semantic analysis |
| T001 | Error | Type mismatch / incompatibility | Type checker |
| PT001 | Error | Implicit type conversion blocked | Runtime |
| PT002 | Error | Cross-type comparison blocked | Runtime |
| PR001 | Error | Division by zero | Runtime |
| S001 | Warning | Hardcoded secret in string literal | Security analyzer |
| S002 | Warning | Dangerous function name | Security analyzer |
| S003 | Warning | Dangerous function call | Security analyzer |
| S004 | Warning | Dangerous shell pattern | Security analyzer |
| S005 | Warning | Secret pattern in string value | Security analyzer |

## Academy ↔ Book Cross-Reference

| Academy Lesson | Book Chapter | Topic |
|----------------|--------------|-------|
| 01 | 01 | Getting Started, Expressions & Operators |
| 02 | 02 | Variables & Types |
| 03 | 04 | Control Flow |
| 04 | 05 | Functions |
| 05 | 02 (partial), 07 (partial) | Type Conversions & IO |
| 06 | 06 | Data Structures |
| 07 | 07 | Standard Library |
| 08 | 08 | Security |
| 09 | 09 | Web Platform |
| 10 | 10 | Database Platform |
| 11 | 11 | AI Platform |
| 12 | 12 | CLI & Tooling |
| 13 | 13 | Cross-Platform |
| 14 | 14 | Language Reference |
| 15 | 15 | Comparison Semantics |
| 16 | 16 | Contributing |
| 17 | 17 | Ecosystem |
| 18 | — | Capstone Project |

## Learning Paths

### Beginner Track (Lessons 01–05)
- Prerequisites: None
- Outcome: Write simple PantherLang programs
- Topics: Variables, expressions, control flow, functions, conversions

### Developer Track (Lessons 01–10)
- Prerequisites: Beginner track
- Outcome: Build applications with data, security, web, and database
- Topics: + Data structures, stdlib, security, web, database

### Professional Track (Lessons 01–18)
- Prerequisites: Developer track
- Outcome: Full-stack development, AI integration, contribution
- Topics: + AI, CLI, cross-platform, contributing, ecosystem

## Certification Blueprint

### PantherLang Foundations
- **Lessons**: 01–05
- **Competencies**: Variables, types, expressions, control flow, functions, conversions
- **Assessment**: Quiz (40 questions) + Practical project (CLI calculator)
- **Duration**: 40 hours study

### PantherLang Developer
- **Lessons**: 01–10
- **Competencies**: + Data structures, stdlib, security, web, database
- **Assessment**: Quiz (60 questions) + Practical project (Web + SQLite application)
- **Duration**: 80 hours study

### PantherLang Professional
- **Lessons**: 01–18
- **Competencies**: + AI, CLI, cross-platform, contribution patterns
- **Assessment**: Exam (100 questions) + Capstone project
- **Duration**: 160 hours study

## Changelog (v1.1.6)

### New in v1.1.6
- Complete Academy: 18 lessons with runnable examples
- Expanded Book: 18 chapters with cross-references
- Comparison Semantics chapter fully expanded
- Contributing and Ecosystem chapters
- Appendix with glossary, index, error codes
- Learning paths and certification blueprint

### v1.1.5
- Foundation Academy lessons (01-05)
- Book chapters 01-15 (Chapter 15 minimal)
- Cookbook README with roadmap
- Security and AI chapters
- Cross-platform support

## References

- **Python**: https://www.python.org/
- **VS Code Extension API**: https://code.visualstudio.com/api
- **Debug Adapter Protocol**: https://microsoft.github.io/debug-adapter-protocol/
- **Language Server Protocol**: https://microsoft.github.io/language-server-protocol/
- **SQLite**: https://www.sqlite.org/
- **OpenAI API**: https://platform.openai.com/
- **Anthropic Claude**: https://docs.anthropic.com/
- **Google Gemini**: https://ai.google.dev/
- **Ollama**: https://ollama.ai/
- **OpenRouter**: https://openrouter.ai/