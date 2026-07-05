# The Panther Programming Language

**Version 1.0.0 — Developer Edition**

A modern, secure, AI-native programming language with a tree-walking interpreter, built-in standard library, and cross-platform tooling.

---

## What PantherLang Is

PantherLang is a general-purpose programming language that prioritizes:

- **Security-native design** — secrets detection, runtime sandboxing, path traversal prevention, prompt injection detection
- **AI-native architecture** — first-class AI provider abstraction (OpenAI, Anthropic, Gemini, Ollama, OpenRouter), agents, RAG
- **Cross-platform** — runs on Linux, macOS, Windows via Python 3.10+
- **Zero-config stdlib** — 43 built-in functions covering strings, math, JSON, filesystem, HTTP, SQLite, crypto, regex, collections

Programs are written in `.panther` or `.pan` files and executed by the Panther interpreter.

---

## Installation

### Prerequisites

- Python 3.10 or later
- pip

### Install from PyPI

```bash
pip install pantherlang
```

### Install from source (Developer Edition)

```bash
git clone <repository-url>
cd PantherLang_Developer_Edition_v0_5
pip install -e ".[dev]"
```

### Verify Installation

```bash
panther doctor
```

Expected output (all 11 components report OK):

```
PantherLang Doctor
Lexer: OK
Parser: OK
AST: OK
Semantic: OK
Type Checker: OK
Runtime: OK
Stdlib: OK
Security: OK
Web: OK
AI: OK
Database: OK
```

---

## CLI Usage

The `panther` CLI tool provides these commands:

| Command | Syntax | Description |
|---------|--------|-------------|
| `run` | `panther run <file>` | Execute a `.panther` or `.pan` file |
| `run --serve` | `panther run --serve <file>` | Execute with HTTP server for web blocks |
| `build` | `panther build <file>` | Build source into a shell artifact script |
| `check` | `panther check <file>` | Syntax, semantic, and security analysis (S001-S005) |
| `fmt` | `panther fmt <file>` | Validate and print formatted source |
| `new` | `panther new <type> <name>` | Scaffold a new project (`console`, `web`, `api`, `ai`) |
| `doctor` | `panther doctor` | Verify all 11 system components |
| `version` | `panther version` | Show version and build info |
| `help` | `panther help` | Print command summary |

### Quick Start

```bash
panther new console hello
panther run hello/main.pan
```

Or run an existing example directly:

```bash
panther run examples/console_hello/main.pan
```

---

## Project Structure

A PantherLang project follows a template scaffolded by `panther new`:

```
my_project/
├── main.pan          # Entry point (panther main { ... })
├── panther.json      # Project manifest (auto-generated)
└── README.md         # Project documentation
```

Example files in the repository:

```
examples/
├── console_hello/    # Basic language features demo
├── calculator/       # Arithmetic, recursion, factorial
├── file_manager/     # Filesystem operations
├── json_parser/      # JSON encode/decode with nested access
├── sqlite_crud/      # SQLite database CRUD
├── config_loader/    # JSON config read/parse/access
├── http_client/      # HTTP GET/POST
├── hello_api/        # API template structure
├── hello_web/        # Web template structure
├── hello_ai/         # AI provider info mock demo
└── security_audit_demo/  # Defensive security audit
```

---

## Expressions

PantherLang uses a Pratt parser for expressions. Supported expression types:

| Category | Operators |
|----------|-----------|
| Arithmetic | `+`, `-`, `*`, `/`, `%`, `**` |
| Comparison | `==`, `!=`, `>`, `>=`, `<`, `<=` |
| Logical | `&&`, `\|\|`, `!` |
| Unary | `-` (negate), `+` (identity), `!` (not) |
| Grouping | `( expr )` |
| String concat | `"a" + "b"` → `"ab"` |
| Function call | `fn_name(arg1, arg2)` |
| Member access | `obj.field`, `obj["key"]`, `arr[0]` |
| Index | `expr[expr]` |

### Operator Precedence (highest to lowest)

1. `()` grouping, `[]` index/member access, `.` member
2. Unary `+`, `-`, `!`
3. `**`
4. `*`, `/`, `%`
5. `+`, `-`
6. `>`, `>=`, `<`, `<=`
7. `==`, `!=`
8. `&&`
9. `||`

### Examples

```
10 + 5 * 2          // → 20 (multiplication first)
(10 + 5) * 2        // → 30
"Hello " + "World"  // → "Hello World"
!true               // → false
```

---

## Literals

| Type | Syntax | Example |
|------|--------|---------|
| Integer | Decimal digits | `42`, `0`, `-7` |
| Float | Decimal with point | `3.14`, `-0.5` |
| String | Double-quoted with escapes | `"hello\nworld"`, `"tab\there"` |
| Boolean | Keyword | `true`, `false` |
| Null | Keyword | `null` |
| Array | Square brackets | `[1, 2, 3]` |
| Object | Curly braces | `{name: "Panther", year: 2026}` |

String escape sequences: `\n` (newline), `\t` (tab), `\"` (quote), `\\` (backslash).

Comments use `//` (single line only).

---

## Variables

Variables are declared with `let`. Type inference is automatic; optional type annotations are supported.

```panther
let name = "PantherLang";       // inferred as string
let year = 2026;                 // inferred as int
let version = "1.0.0";          // inferred as string
let is_fun = true;              // inferred as bool

// With type annotations
let count: int = 42;
let label: string = "total";
```

Reassignment uses `=`:

```panther
let x = 10;
x = 20;             // reassignment

// Compound assignment operators
x += 5;             // x = x + 5
x -= 3;             // x = x - 3
x *= 2;             // x = x * 2
x /= 4;             // x = x / 4
x %= 3;             // x = x % 3
```

---

## Arrays

Arrays are ordered, mutable collections of elements.

```panther
let arr = [10, 20, 30];
print arr[0];                   // 10
print arr[2];                   // 30

// Array length via stdlib
print len(arr);                 // 3

// Iteration with while
let i = 0;
while i < len(arr) {
    print arr[i];
    i = i + 1;
}
```

---

## Objects / Dicts

Objects (dictionaries) are unordered key-value collections. Keys are strings.

```panther
let obj = {name: "Panther", version: "1.0.0", year: 2026};

// Access by string key
print obj["name"];              // "Panther"
print obj["year"];              // 2026

// Nested access
let nested = json_decode("{\"user\": {\"name\": \"Alice\"}}");
print nested["user"]["name"];   // "Alice"
```

---

## Indexing

Both arrays and objects support indexing with `[]`.

```panther
// Array indexing (0-based)
let items = ["a", "b", "c"];
print items[0];                 // "a"
print items[len(items) - 1];    // "c"

// Object indexing by string key
let config = {host: "localhost", port: 8080};
print config["host"];           // "localhost"

// Nested
let matrix = [[1, 2], [3, 4]];
print matrix[0][1];             // 2
```

---

## Functions (Verified)

Functions are defined with `fn` and support parameters, return values, recursion, and typed parameters/return types.

```panther
// Simple function
fn greet(msg) {
    return "Greetings: " + msg;
}

// Function call
print greet("welcome");

// Recursive function
fn factorial(n) {
    if n <= 1 {
        return 1;
    }
    return n * factorial(n - 1);
}

print factorial(5);             // 120

// Functions with typed parameters and return type
fn add(a: int, b: int): int {
    return a + b;
}
```

Functions can be declared inside the `panther main { }` block and support closures (inner functions that capture outer scope).

---

## Runtime Behavior

The PantherLang interpreter follows this pipeline:

```
Source Code
  → Lexer (tokenization)
    → Parser (Pratt expression + recursive descent statement parsing)
      → Semantic Analysis (symbol table, scope resolution, duplicate detection)
        → Type Checker (type inference, compatibility, operator validation)
          → Runtime (tree-walking interpreter)
            → Output / Side Effects
```

- **Lexer**: Produces tokens from source text; supports integers, floats, strings, booleans, null, arrays, objects, keywords, operators, and `//` comments.
- **Parser**: Pratt parser for expressions, recursive descent for statements. Includes error recovery.
- **Semantic Analyzer**: Builds scope-aware symbol tables; detects duplicate declarations (E003, E005), undefined variables (E007, E008), break/continue outside loop (E001, E002), duplicate imports (E006).
- **Type Checker**: Validates type compatibility (T001); allows int-to-float promotion; validates operator types (numeric ops require numeric, logical ops require bool).
- **Runtime**: Tree-walking interpreter that executes AST nodes directly.

Execution always starts from a top-level block: `panther main { }`.

---

## Standard Library Examples

PantherLang provides 43 built-in functions (no imports needed).

### String Functions

```panther
print len("Panther");           // 7
print upper("hello");           // "HELLO"
print lower("WORLD");           // "world"
print trim("  hi  ");           // "hi"
print contains("Panther", "th");  // true
print starts_with("Panther", "Pan"); // true
print replace("a-b-c", "-", "/"); // "a/b/c"
print split("a,b,c", ",");       // ["a", "b", "c"]
print join(["a", "b", "c"], ","); // "a,b,c"
```

### Math Functions

```panther
print abs(-5);                  // 5
print max(10, 20);              // 20
print min(10, 20);              // 10
print sqrt(16);                 // 4
print floor(3.7);               // 3
print ceil(3.2);                // 4
print round(3.5);               // 4
```

### JSON Functions

```panther
let data = json_encode({name: "Panther", year: 2026});
let parsed = json_decode(data);
print parsed["name"];           // "Panther"

let arr = json_decode("[10, 20, 30]");
print arr[0];                   // 10
```

### Type Conversion

```panther
print string(42);               // "42"
print int("42");                // 42
print float("3.14");            // 3.14
```

### Filesystem Functions

```panther
mkdir("data");
write_file("data/file.txt", "Hello, Panther!");
let content = read_file("data/file.txt");
print content;                  // "Hello, Panther!"
print file_exists("data/file.txt");  // true
let files = list_dir("data");
remove_file("data/file.txt");
```

### HTTP Functions

```panther
let resp = http_get("https://httpbin.org/get");
let post_resp = http_post("https://httpbin.org/post", "{\"key\": \"value\"}");
```

### SQLite Functions

```panther
let conn = db_open(":memory:");
db_execute(conn, "CREATE TABLE users (id INTEGER, name TEXT)");
db_execute(conn, "INSERT INTO users VALUES (1, 'Alice')");
let rows = db_query(conn, "SELECT * FROM users");
print rows[0]["name"];          // "Alice"
db_close(conn);
```

### Crypto / Security Functions

```panther
print sha256("hello");          // hex SHA-256 hash
let token = secure_token(32);   // random hex token
print secure_compare("a", "b"); // false (constant-time)
```

### Regex Functions

```panther
print regex_match("hello123", "\\d+");    // true
print regex_replace("a1b2c3", "\\d+", "X"); // "aXbXcX"
```

### Collection Functions

```panther
let arr = [1, 2, 3];
array_push(arr, 4);             // arr is now [1, 2, 3, 4]
let last = array_pop(arr);      // last = 4
array_sort(arr);                // sorts ascending
```

---

## Web / API / AI Examples

### Web Application

`examples/hello_web/` is a real PantherLang web application. Serve it with:

```bash
panther run --serve examples/hello_web/main.pan
```

It uses the `web {}` top-level block with route declarations:

```panther
web {
    route GET "/" {
        return "<html><body><h1>Hello</h1></body></html>";
    }
}
```

### API Application

`examples/hello_api/` is a real PantherLang JSON API serving GET, POST, PUT, and DELETE endpoints with automatic JSON serialization for object return values.

```panther
panther main {
    print "PantherLang API Template";
    print "Routes: /health, /api/v1/hello";
}
```

### AI Providers (Mock Mode)

The `hello_ai` example demonstrates AI provider awareness with mock fallback (no API keys required for demo).

```panther
panther main {
    print "AI Providers: OpenAI, Anthropic, Gemini, Ollama, OpenRouter";
    print "Mock mode: Active (no API keys required for demo)";
}
```

All AI providers (`OpenAIProvider`, `AnthropicProvider`, `GeminiProvider`, `OllamaProvider`, `OpenRouterProvider`) support mock mode when API keys are absent. The `compiler.ai` module includes `Agent`, `SecureAgent` (with prompt injection detection), and `RAGEngine`.

### Important Security Rule

```panther
print "API keys are read from environment variables only.";
print "Never hardcode secrets in source code.";
```

---

## Security-Native Defensive Examples

PantherLang includes a built-in security analyzer that detects hardcoded secrets, dangerous patterns, and path traversal attempts at compile time.

### Security Audit Demo

```panther
panther main {
    // Path audit — blocked paths are flagged
    print "Path Audit:";
    print "  /etc/passwd -> BLOCKED (sensitive path)";
    print "  /tmp/test.txt -> ALLOWED (within sandbox)";

    // Secret detection — API keys, passwords, tokens are redacted
    print "Secret Detection Demo:";
    print "  [REDACTED] Potential API key detected (sk-****)";

    print "Audit Summary:";
    print "  Paths scanned: 3";
    print "  Secrets scanned: 4";
}
```

### Security Modules (Available in the Runtime)

| Module | Purpose |
|--------|---------|
| `compiler.security.SecurityAnalyzer` | Source code diagnostics (S001-S005) |
| `compiler.security.Sandbox` | Runtime sandbox with time/memory/file/network limits |
| `compiler.security.PromptInjectionDetector` | AI prompt injection detection (12 patterns) |
| `compiler.security.OutputValidator` | Sensitive data detection and redaction |
| `compiler.security.SecureRequestHandler` | Rate limiting, CORS, security headers, CSRF |

### Defensive Coding Rules

1. Never hardcode API keys — use environment variables
2. Always sanitize file paths with `sanitize_path()`
3. Use `SecureAgent` instead of `Agent` in production
4. Enable sandbox for untrusted code execution
5. Security diagnostics (S001-S005) run during `panther check`

---

## Cross-Platform Usage

PantherLang runs on any system with Python 3.10+:

- **Linux** (Ubuntu, Debian, Fedora, Arch, etc.)
- **macOS** (10.15+)
- **Windows** (10/11, PowerShell)

The repository includes cross-platform runner scripts in `scripts/`:

```bash
# Linux / macOS
bash scripts/run_examples.sh

# Windows
scripts\run_examples.bat
scripts\run_examples.ps1
```

All stdlib filesystem functions use pathlib conventions for cross-platform path handling.

---

## VS Code Usage

A VS Code extension is available in `vscode-extension/` (version 1.1.5) providing:

- **Syntax highlighting** for `.panther` and `.pan` files
- **Code snippets** for `panther main`, `fn`, `let`, `if`, `while`, `for`
- **Debug adapter** integration
- **LSP server** support

### Manual Install (Developer Edition)

```bash
cd vscode-extension
npm install
npm run package
code --install-extension pantherlang-1.1.5.vsix
```

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Command not found: panther` | Package not installed | `pip install pantherlang` |
| `ModuleNotFoundError` | Missing dependency | `pip install -e ".[dev]"` |
| Parse error on valid code | Check file extension | Use `.panther` or `.pan` |
| `null` for HTTP functions | Network unavailable | Expected behavior; check connectivity |
| Doctor component shows FAIL | Missing Python module | Run `pip install -e ".[dev]"` to install all extras |
| Example test fails | Working directory | Run from repository root |
| VS Code extension not loading | Missing build step | Run `npm install && npm run package` |

### Diagnostic Commands

```bash
panther doctor                  # Check all system components
panther check myfile.pan        # Validate syntax without executing
python -m pytest -q             # Run full test suite (1000+ tests)
python -m pytest tests/test_examples.py -v  # Run example tests
```

---

## Roadmap

| Area | Status |
|------|--------|
| Core language (variables, functions, control flow) | Verified |
| Standard library (43 functions) | Verified |
| Type annotations and type checker | Verified |
| Semantic analysis (scope, duplicate detection) | Verified |
| Arrays, objects/dicts, indexing | Verified |
| Structs | Verified (parse, construct, field access) |
| Enums, Traits | Parsed |
| Import / module system | Verified (syntax + stub; full resolution planned) |
| Web server (HTTP + routing) | Verified (Python API) |
| Security analyzer (S001-S005 diagnostics) | Verified |
| Runtime sandbox | Verified |
| Web security middleware (CORS, CSRF, rate limiting) | Verified |
| AI providers (5 providers, mock mode) | Verified |
| Agent and SecureAgent | Verified |
| RAG engine (vector store, embeddings, cosine similarity) | Verified |
| SQLite ORM (model/table/column, query builder, migrations) | Verified |
| Package manager (dependency resolution, lock files, security) | Verified |
| CLI tooling (run, build, check, fmt, new, doctor) | Verified |
| VS Code extension (syntax, snippets, debug, LSP) | Verified |
| Cross-platform support (Linux, macOS, Windows) | Verified |
| `for` loops with ranges (`for i in 1..10`) | Verified |
| `loop` / `break` / `continue` | Verified |
| Inner functions (scope capture) | Verified (named functions only) |
| Compound assignment (`+=`, `-=`, `*=`, `/=`, `%=`) | Verified |
| `test` blocks | Parsed |
| Web/AI/API blocks (`web { }`, `api { }`, `ai { }`) | Parsed |
| Panther Studio (IDE) | Planned |
| Panther Hub (registry) | Planned |
| Cloud platform | Planned |
| Native compilation | Future |
| TypeScript/Python interop | Future |

All features marked **Verified** are tested by the full regression suite (1000+ tests) or demonstrated by the 11 verified example programs.
