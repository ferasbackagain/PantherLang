# PantherLang Language Feature Map

Maps every verified language feature to examples that demonstrate it.

---

## Core Syntax

| Feature | Syntax | Example(s) |
|---------|--------|------------|
| Program block | `panther main { ... }` | all examples, conformance/* |
| Variable declaration | `let x = val;` | all examples, conformance/02_variables |
| Type annotation | `let x: int = 5;` | console_hello, calculator |
| Assignment | `x = val;` | calculator, file_manager, conformance/03_assignment |
| Compound assignment | `x += 1;` | file_manager, conformance/04_compound_assignment |
| Comment | `// text` | hello_ai, security_audit_demo |
| Print | `print expr;` | all examples |

---

## Literals

| Type | Syntax | Example(s) |
|------|--------|------------|
| Integer | `42` | all examples, conformance/01_literals |
| Float | `3.14` | conformance/01_literals |
| String | `"hello"` | all examples, conformance/01_literals |
| Boolean | `true`, `false` | calculator, conformance/01_literals |
| Null | `null` | http_client, conformance/01_literals |
| Array | `[1, 2, 3]` | json_parser, config_loader, conformance/01_literals |
| Object | `{key: val}` | json_parser, conformance/01_literals |

---

## Expressions

| Operator | Syntax | Example(s) |
|----------|--------|------------|
| Addition | `a + b` | calculator, console_hello, conformance/06_expressions_operators |
| Subtraction | `a - b` | calculator |
| Multiplication | `a * b` | calculator, conformance/06_expressions_operators |
| Division | `a / b` | calculator |
| Modulus | `a % b` | calculator |
| Power | `a ** b` | calculator |
| Equal | `a == b` | calculator, conformance/06_expressions_operators |
| Not equal | `a != b` | conformance/06_expressions_operators |
| Greater than | `a > b` | calculator, conformance/06_expressions_operators |
| Less than | `a < b` | calculator, conformance/06_expressions_operators |
| Greater/equal | `a >= b` | conformance/06_expressions_operators |
| Less/equal | `a <= b` | conformance/06_expressions_operators |
| Logical AND | `a && b` | calculator (if conditions) |
| Logical OR | `a \|\| b` | (stdlib/tests) |
| Logical NOT | `!a` | conformance/06_expressions_operators |
| String concat | `"a" + "b"` | all examples, conformance/06_expressions_operators |
| Grouping | `(a + b)` | calculator, conformance/06_expressions_operators |

---

## Control Flow

| Feature | Syntax | Example(s) |
|---------|--------|------------|
| If | `if cond { ... }` | calculator, hello_ai, conformance/09_control_flow |
| If/else | `if cond { ... } else { ... }` | calculator, conformance/09_control_flow |
| While loop | `while cond { ... }` | file_manager, config_loader, conformance/10_loops |
| For range | `for i in start..end { ... }` | conformance/10_loops |
| Loop | `loop { ... }` | conformance/10_loops |
| Break | `break;` | conformance/10_loops |
| Continue | `continue;` | conformance/10_loops |

---

## Functions

| Feature | Syntax | Example(s) |
|---------|--------|------------|
| Function definition | `fn name(params) { ... }` | console_hello, calculator, hello_api, hello_web, hello_ai, conformance/07_functions |
| Return value | `return expr;` | console_hello, calculator, hello_api, hello_web, conformance/07_functions |
| No-return | `return;` | (runtime/tests) |
| Recursion | `fn f(n) { ... f(n-1) ... }` | calculator (factorial), conformance/08_recursion |
| Typed parameters | `fn f(x: int) { ... }` | (types/tests) |
| Typed return | `fn f(): int { ... }` | (types/tests) |

---

## Data Structures

| Feature | Syntax | Example(s) |
|---------|--------|------------|
| Array literal | `[1, 2, 3]` | json_parser, config_loader, conformance/05_arrays_objects_indexing |
| Array indexing | `arr[0]` | file_manager, json_parser, config_loader, conformance/05_arrays_objects_indexing |
| Nested array index | `matrix[0][1]` | json_parser |
| Object literal | `{name: "Panther"}` | json_parser, conformance/05_arrays_objects_indexing |
| Object indexing | `obj["key"]` | json_parser, sqlite_crud, config_loader, conformance/05_arrays_objects_indexing |
| Nested object access | `obj["outer"]["inner"]` | json_parser, config_loader |
| Struct definition | `struct Name { field1 field2 }` | conformance/11_structs |
| Struct construction | `Name(arg1, arg2)` | conformance/11_structs |
| Struct member access | `instance.field` | conformance/11_structs |

---

## Standard Library

| Function | Category | Example(s) |
|----------|----------|------------|
| `len()` | string/collection | file_manager, json_parser, sqlite_crud, config_loader, conformance/12_stdlib_string_math_json |
| `string()` | conversion | all examples, conformance/12_stdlib_string_math_json |
| `int()` | conversion | conformance/12_stdlib_string_math_json |
| `float()` | conversion | conformance/12_stdlib_string_math_json |
| `upper()` | string | conformance/12_stdlib_string_math_json |
| `lower()` | string | conformance/12_stdlib_string_math_json |
| `contains()` | string | conformance/12_stdlib_string_math_json |
| `starts_with()` | string | (stdlib/tests) |
| `replace()` | string | conformance/12_stdlib_string_math_json |
| `split()` | string | conformance/12_stdlib_string_math_json |
| `join()` | string | conformance/12_stdlib_string_math_json |
| `trim()` | string | conformance/12_stdlib_string_math_json |
| `substring()` | string | (stdlib/tests) |
| `ends_with()` | string | (stdlib/tests) |
| `abs()` | math | conformance/12_stdlib_string_math_json |
| `max()` | math | conformance/12_stdlib_string_math_json |
| `min()` | math | (stdlib/tests) |
| `pow()` | math | conformance/12_stdlib_string_math_json |
| `sqrt()` | math | conformance/12_stdlib_string_math_json |
| `floor()` | math | conformance/12_stdlib_string_math_json |
| `ceil()` | math | conformance/12_stdlib_string_math_json |
| `round()` | math | conformance/12_stdlib_string_math_json |
| `random()` | math | (stdlib/tests) |
| `randint()` | math | (stdlib/tests) |
| `time()` | time | (stdlib/tests) |
| `sleep()` | time | (stdlib/tests) |
| `json_encode()` | JSON | json_parser, config_loader, conformance/12_stdlib_string_math_json |
| `json_decode()` | JSON | json_parser, config_loader, conformance/12_stdlib_string_math_json |
| `sha256()` | crypto | (stdlib/tests) |
| `hmac_sha256()` | crypto | (stdlib/tests) |
| `secure_token()` | crypto | (stdlib/tests) |
| `secure_compare()` | crypto | (stdlib/tests) |
| `sanitize_path()` | security | (security/tests) |
| `sanitize_html()` | security | (security/tests) |
| `read_file()` | filesystem | file_manager, config_loader, conformance/13_filesystem |
| `write_file()` | filesystem | file_manager, config_loader, conformance/13_filesystem |
| `file_exists()` | filesystem | file_manager, conformance/13_filesystem |
| `mkdir()` | filesystem | file_manager, conformance/13_filesystem |
| `list_dir()` | filesystem | file_manager, conformance/13_filesystem |
| `remove_file()` | filesystem | file_manager, config_loader, conformance/13_filesystem |
| `http_get()` | HTTP | http_client, conformance/15_http_client |
| `http_post()` | HTTP | http_client, conformance/15_http_client |
| `regex_match()` | regex | (stdlib/tests) |
| `regex_replace()` | regex | (stdlib/tests) |
| `regex_split()` | regex | (stdlib/tests) |
| `array_push()` | collections | (stdlib/tests) |
| `array_pop()` | collections | (stdlib/tests) |
| `array_sort()` | collections | (stdlib/tests) |
| `array_reverse()` | collections | (stdlib/tests) |
| `db_open()` | SQLite | sqlite_crud, conformance/14_sqlite_crud |
| `db_execute()` | SQLite | sqlite_crud, conformance/14_sqlite_crud |
| `db_query()` | SQLite | sqlite_crud, conformance/14_sqlite_crud |
| `db_close()` | SQLite | sqlite_crud, conformance/14_sqlite_crud |

---

## Security Features (Verified)

| Feature | Module | Verified By |
|---------|--------|------------|
| Secret detection (S001, S005) | `compiler.security.SecurityAnalyzer` | tests/security/, conformance/16_security_audit |
| Dangerous call detection (S002, S003) | `compiler.security.SecurityAnalyzer` | tests/security/ |
| Shell pattern detection (S004) | `compiler.security.SecurityAnalyzer` | tests/security/ |
| Runtime sandbox (time/memory/file/network limits) | `compiler.security.Sandbox` | tests/security/ |
| Read-only sandbox | `compiler.security.ReadOnlySandbox` | tests/security/ |
| Safe execution sandbox | `compiler.security.SafeExecSandbox` | tests/security/ |
| Path traversal prevention | `compiler.security.Sandbox` | tests/security/ |
| Path sanitization | `compiler.stdlib.stdlib_security.PathSafety` | tests/security/ |
| Web security headers (CSP, HSTS, XFO, etc.) | `compiler.web.security.SecurityHeaders` | tests/security/ |
| CSRF token generation/validation | `compiler.web.security.CSRFProtection` | tests/security/ |
| Rate limiting (sliding window) | `compiler.web.security.RateLimiter` | tests/security/ |
| CORS validation (wildcard support) | `compiler.web.security.CORSValidator` | tests/security/ |
| Prompt injection detection (12 patterns) | `compiler.security.PromptInjectionDetector` | tests/security/ |
| Output sanitization (secrets redaction) | `compiler.security.OutputValidator` | tests/security/ |
| Tool call audit logging | `compiler.security.ToolCallAudit` | tests/security/ |
| Secure cookies (HttpOnly, Secure, SameSite) | `compiler.web.security.CookieSecurity` | tests/security/ |
| JWT structure validation | `compiler.web.security.JWTSafety` | tests/security/ |
| HTML sanitization | `compiler.stdlib.stdlib_security.InputValidator` | tests/security/ |
| Email validation | `compiler.stdlib.stdlib_security.InputValidator` | tests/security/ |
| Secure random tokens | `compiler.stdlib.stdlib_security.SecureRandom` | tests/security/ |

---

## AI Platform (Verified)

| Feature | Module | Verified By |
|---------|--------|------------|
| OpenAI provider (GPT-4o, embeddings) | `compiler.ai.providers.OpenAIProvider` | tests/, conformance/17_ai_mock |
| Anthropic provider (Claude Sonnet 4) | `compiler.ai.providers.AnthropicProvider` | tests/ |
| Gemini provider (Gemini 2.0 Flash) | `compiler.ai.providers.GeminiProvider` | tests/ |
| Ollama provider (local Llama 3, Mistral) | `compiler.ai.providers.OllamaProvider` | tests/ |
| OpenRouter provider | `compiler.ai.providers.OpenRouterProvider` | tests/ |
| Agent (conversation, tool calling) | `compiler.ai.agents.Agent` | tests/ |
| SecureAgent (injection detection, audit) | `compiler.ai.secure_agent.SecureAgent` | tests/ |
| RAG engine (vector store, cosine similarity) | `compiler.ai.rag.RAGEngine` | tests/ |
| Embedding provider abstraction | `compiler.ai.rag.EmbeddingProvider` | tests/ |
| Document store | `compiler.ai.rag.VectorStore` | tests/ |

---

## Web Platform (Verified)

| Feature | Module | Verified By |
|---------|--------|------------|
| HTTP server (host/port) | `compiler.web.server.HttpServer` | tests/ |
| Router (method + path dispatch) | `compiler.web.server.Router` | tests/ |
| Route registration (get/post/put/delete) | `compiler.web.server.Router` | tests/ |
| JSON responses | `compiler.web.server` | tests/ |
| HTML response auto-detection | `compiler.web.server` | tests/ |
| Query string parsing | `compiler.web.server` | tests/ |
| Path parameters `{id}` | `compiler.web.server` | tests/ |
| 404 handling | `compiler.web.server` | tests/ |
| Web block `web {}` | `compiler.parser` | tests/ |
| API block `api {}` | `compiler.parser` | tests/ |
| Route statement `route GET/POST/PUT/DELETE` | `compiler.parser` | tests/ |
| `panther run --serve` | `compiler.runtime` | tests/ |
| Static file serving | Not implemented | -- |

---

## Database Platform (Verified)

| Feature | Module | Verified By |
|---------|--------|------------|
| SQLite engine (connection management) | `compiler.database.SqliteEngine` | tests/ |
| Model/Table/Column schema definitions | `compiler.database.orm` | tests/ |
| QueryBuilder (where, order, limit) | `compiler.database.orm` | tests/ |
| Migration runner (versioned SQL) | `compiler.database.orm` | tests/ |

---

## CLI and Tooling (Verified)

| Feature | Command | Verified By |
|---------|---------|------------|
| Run source files | `panther run <file>` | test_examples.py, all examples |
| Build artifact | `panther build <file>` | tests/ |
| Check syntax | `panther check <file>` | tests/ |
| Format source | `panther fmt <file>` | tests/ |
| Scaffold project | `panther new <type> <name>` | tests/ |
| System diagnostics | `panther doctor` | tests/ |
| Version info | `panther version` | tests/ |
| VS Code extension (syntax highlighting) | vscode-extension/ | vscode tests |
| VS Code snippets | vscode-extension/ | vscode tests |
| LSP server | vscode-extension/ | vscode tests |
| Debug adapter | vscode-extension/ | vscode tests |
