# PantherLang Examples Index

11 verified, runnable examples that serve as the source of truth for the language.

All examples can be executed with `panther run <path>` from the repository root.

---

## 1. console_hello

**Path:** `examples/console_hello/main.pan`
**README:** `examples/console_hello/README.md`

Demonstrates:
- `panther main { }` block
- `let` variable declarations (string, int, bool)
- `print` statement
- String concatenation with `+`
- `fn` function definition with `return`
- `string()` type conversion
- Function call with argument

**Expected output:** Greeting with name, year, version, boolean, and function result.

---

## 2. calculator

**Path:** `examples/calculator/calc.pan`
**README:** `examples/calculator/README.md`

Demonstrates:
- Arithmetic operators: `+`, `-`, `*`, `/`, `%`, `**`
- Comparison operators: `>`, `==`, `<`
- Recursive function (`factorial`)
- `if` / `else` control flow
- `string()` type conversion

**Expected output:** Calculations with `a=42, b=7`, comparisons, factorial(5)=120, factorial(7)=5040.

---

## 3. hello_api

**Path:** `examples/hello_api/main.pan`
**README:** `examples/hello_api/README.md`

Demonstrates:
- `api {}` block with GET, POST, PUT, DELETE routes
- Automatic JSON serialization of object return values
- Path parameter extraction via `{id}` syntax
- `panther run --serve` for HTTP serving

**Current behavior:** Real API server. Start with `panther run --serve examples/hello_api/main.pan`.

---

## 4. hello_web

**Path:** `examples/hello_web/main.pan`
**README:** `examples/hello_web/README.md`

Demonstrates:
- `web {}` block with GET and POST routes
- HTML page serving with auto-detected Content-Type
- HTML form with POST handler
- Path parameter extraction via `{name}` syntax
- `panther run --serve` for HTTP serving

**Current behavior:** Real web server. Start with `panther run --serve examples/hello_web/main.pan`.

---

## 5. hello_ai

**Path:** `examples/hello_ai/main.pan`
**README:** `examples/hello_ai/README.md`

Demonstrates:
- AI template project structure
- `fn` with `if` branching on string comparison
- Mock AI provider info (no API keys required)
- Security best practice comments

**Current behavior:** Prints AI provider information in mock mode.

---

## 6. security_audit_demo

**Path:** `examples/security_audit_demo/main.pan`
**README:** `examples/security_audit_demo/README.md`

Demonstrates:
- Defensive security audit patterns
- Path audit (allowlist-based blocking)
- Secret/credential pattern detection (redaction)
- Audit summary with variables
- `string()` type conversion on int values

**Current behavior:** Prints audit results for path scanning, secret detection, and summary.

---

## 7. file_manager

**Path:** `examples/file_manager/main.pan`
**README:** `examples/file_manager/README.md`

Demonstrates:
- `mkdir()` — create directories
- `write_file()` — write text files
- `read_file()` — read text files
- `list_dir()` — list directory contents
- `file_exists()` — check file existence
- `remove_file()` — delete files
- `while` loop for iteration
- `len()` array length
- Array indexing `files[i]`
- `string()` type conversion

---

## 8. sqlite_crud

**Path:** `examples/sqlite_crud/main.pan`
**README:** `examples/sqlite_crud/README.md`

Demonstrates:
- `db_open()` — open SQLite database (in-memory)
- `db_execute()` — execute INSERT, UPDATE, DELETE
- `db_query()` — execute SELECT queries
- `db_close()` — close connection
- Array indexing on query results (`rows[0]`)
- Dict key access on rows (`rows[0]["age"]`)
- `len()` on result arrays
- `string()` type conversion

---

## 9. http_client

**Path:** `examples/http_client/main.pan`
**README:** `examples/http_client/README.md`

Demonstrates:
- `http_get()` — fetch URL
- `http_post()` — POST JSON data
- `null` check with `if`
- `len()` on response string
- Graceful null handling when network is unavailable

---

## 10. json_parser

**Path:** `examples/json_parser/main.pan`
**README:** `examples/json_parser/README.md`

Demonstrates:
- `json_encode()` — object to JSON string
- `json_decode()` — JSON string to object/array
- Object literal `{name: "Panther", version: "1.0.0", year: 2026}`
- Dict key access `parsed["name"]`
- Array indexing `arr[0]`
- Nested access `nested["user"]["name"]`
- `len()` on arrays
- `string()` type conversion

---

## 11. config_loader

**Path:** `examples/config_loader/main.pan`
**README:** `examples/config_loader/README.md`

Demonstrates:
- `write_file()` — create config file
- `read_file()` — read config file
- `json_decode()` — parse JSON configuration
- Nested object access (`config["database"]["host"]`)
- Array access within nested objects
- `while` loop for array iteration
- `remove_file()` — cleanup
- `string()` type conversion
- `len()` on arrays

---

## Run All Examples

```bash
# From repository root:
python -m pytest tests/test_examples.py -v
```
