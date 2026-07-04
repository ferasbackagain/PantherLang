# PantherLang AI Knowledge Pack v1.1.5

**Version:** 1.1.5
**Release Date:** 2026-07-04
**Status:** Public Release

---

## Purpose

This document consolidates all AI-relevant knowledge about PantherLang for LLM consumption. It enables AI agents to understand, generate, and debug PantherLang code effectively.

---

## ⚠️ Important Disclaimer

> **Local documentation improves AI-agent understanding but does NOT guarantee external AI model recognition until published/indexed.**
>
> This knowledge pack is designed for:
> - Local AI coding assistants (Cursor, Copilot, Continue, etc.)
> - RAG systems with access to this repository
> - Fine-tuning datasets for PantherLang-specialized models
> - Developer reference during coding sessions
>
> It does NOT automatically make public LLMs (ChatGPT, Claude, Gemini, etc.) "know" PantherLang unless they have been trained on or given access to this content.

---

## Language Identity

| Property | Value |
|----------|-------|
| **Name** | PantherLang |
| **Version** | 1.1.5 |
| **Edition** | Stable (formerly Developer Edition) |
| **File Extensions** | `.panther`, `.pan` |
| **Entry Point** | `panther main { }` block |
| **Paradigm** | Imperative, structured, tree-walking interpreted |
| **Type System** | Static with inference, explicit conversion only |
| **Runtime** | Python 3.10+ (tree-walking interpreter) |
| **License** | Proprietary (see LICENSE) |

---

## Core Syntax Reference

### Program Structure

```panther
// Every executable PantherLang file MUST have this:
panther main {
    // All executable code here
    let x = 42;
    print "Hello";
    
    // Functions can be declared inside
    fn greet(name) {
        return "Hello, " + name;
    }
    print greet("World");
}
```

### Top-Level Blocks (also supported)

```panther
web { ... }       // Web server routes
api { ... }       // API routes
ai { ... }        // AI configuration
test "name" { ... } // Test blocks
```

### Variables

```panther
// Type inference (preferred)
let name = "PantherLang";    // string
let year = 2026;             // int
let pi = 3.14;               // float
let active = true;           // bool
let empty = null;            // null

// Explicit type annotations (verified by type checker)
let count: int = 42;
let label: string = "total";
let ratio: float = 0.5;
let flag: bool = false;
let any_val: any = null;
```

### Reassignment & Compound Assignment

```panther
let x = 10;
x = 20;          // reassignment
x += 5;          // x = x + 5
x -= 3;          // x = x - 3
x *= 2;          // x = x * 2
x /= 4;          // x = x / 4
x %= 3;          // x = x % 3
```

---

## Operators

### Precedence (Highest to Lowest)

| Level | Operators | Associativity |
|-------|-----------|---------------|
| 1 | `()` grouping, `[]` index, `.` member | Left |
| 2 | Unary `+`, `-`, `!` | Right |
| 3 | `**` | Right |
| 4 | `*`, `/`, `%` | Left |
| 5 | `+`, `-` | Left |
| 6 | `>`, `>=`, `<`, `<=` | Left |
| 7 | `==`, `!=` | Left |
| 8 | `&&` | Left |
| 9 | `\|\|` | Left |

### Categories

```panther
// Arithmetic
a + b, a - b, a * b, a / b, a % b, a ** b

// Comparison (NO implicit conversion - strict types required)
a == b, a != b, a > b, a >= b, a < b, a <= b

// Logical
a && b, a \|\| b, !a

// String concatenation (explicit conversion required)
"text" + string(42)    // OK
"text" + 42            // TYPE ERROR PT001
```

---

## Control Flow

### Conditional

```panther
if condition {
    // true branch
} elif other_condition {
    // alternative
} else {
    // fallback
}
```

### Loops

```panther
while condition {
    // repeat while true
}

// Range-based for loop
for i in 0..10 {      // 0 to 9
    print i;
}
for i in 1..=10 {     // 1 to 10 (inclusive)
    print i;
}

// Infinite loop with break/continue
loop {
    if condition { break; }
    if skip_condition { continue; }
}
```

---

## Functions

```panther
// Basic function
fn greet(msg) {
    return "Greetings: " + msg;
}

// With typed parameters and return
fn add(a: int, b: int): int {
    return a + b;
}

// Recursion
fn factorial(n) {
    if n <= 1 {
        return 1;
    }
    return n * factorial(n - 1);
}

// Closures (inner functions capture outer scope)
fn outer() {
    let x = 10;
    fn inner() {
        return x + 5;  // captures x
    }
    return inner;
}
```

---

## Data Structures

### Arrays (Ordered, Mutable)

```panther
let arr = [10, 20, 30];
print arr[0];           // 10
print len(arr);         // 3

// Iteration
let i = 0;
while i < len(arr) {
    print arr[i];
    i = i + 1;
}

// Nested
let matrix = [[1, 2], [3, 4]];
print matrix[0][1];     // 2
```

### Objects/Dictionaries (Unordered, String Keys)

```panther
let obj = {name: "Panther", version: "1.1.5", year: 2026};
print obj["name"];      // "Panther"
print obj["year"];      // 2026

// Nested
let config = {db: {host: "localhost", port: 5432}};
print config["db"]["host"];  // "localhost"
```

### Structs (Named, Typed Fields)

```panther
struct Point {
    x y
}

let p = Point(10, 20);
print p.x;    // 10
print p.y;    // 20
```

### Enums and Traits (Parsed, Limited Runtime)

```panther
enum Color {
    RED GREEN BLUE
}

trait Drawable {
    fn draw();
}
```

---

## Standard Library (43 Functions)

### String (11)
`len`, `substring`, `contains`, `starts_with`, `ends_with`, `upper`, `lower`, `trim`, `replace`, `split`, `join`

### Math (10)
`abs`, `max`, `min`, `pow`, `sqrt`, `floor`, `ceil`, `round`, `random`, `randint`

### JSON (2)
`json_encode`, `json_decode`

### Time (2)
`time`, `sleep`

### Type Conversion (3)
`int`, `float`, `string`

### Crypto (4)
`sha256`, `hmac_sha256`, `secure_token`, `secure_compare`

### Security (2)
`sanitize_path`, `sanitize_html`

### Filesystem (6)
`read_file`, `write_file`, `file_exists`, `mkdir`, `list_dir`, `remove_file`

### HTTP (2)
`http_get`, `http_post`

### Regex (3)
`regex_match`, `regex_replace`, `regex_split`

### Collections (4)
`array_push`, `array_pop`, `array_sort`, `array_reverse`

### SQLite (4)
`db_open`, `db_close`, `db_execute`, `db_query`

---

## Type Conversion Policy (CRITICAL)

**PantherLang does NOT perform implicit type conversion.**

```panther
// These are TYPE ERRORS (PT001):
let x = 10 + "5";       // int + string
let y = "hello" + 42;   // string + int
if 10 == "10" { }       // int == string
if true == 1 { }        // bool == int

// CORRECT - explicit conversion:
let x = 10 + int("5");      // 15
let y = "hello" + string(42); // "hello42"
if 10 == int("10") { }      // true
if to_bool(1) == true { }   // depends on to_bool implementation
```

**Conversion functions:** `int()`, `float()`, `string()`, `to_string()`, `to_int()`, `to_number()`, `to_bool()`

---

## Error Codes

| Code | Category | Description |
|------|----------|-------------|
| E001 | Control Flow | `break` outside loop |
| E002 | Control Flow | `continue` outside loop |
| E003 | Semantic | Duplicate function declaration |
| E005 | Semantic | Duplicate variable declaration |
| E006 | Semantic | Duplicate import |
| E007 | Semantic | Undefined variable referenced |
| E008 | Semantic | Undefined function/symbol |
| T001 | Type | Type mismatch / incompatibility |
| PT001 | Type | Comparison type mismatch (strict) |
| PR001 | Runtime | Division by zero |
| S001 | Security | Hardcoded secret in string literal |
| S002 | Security | Dangerous function name (exec, eval, system) |
| S003 | Security | Dangerous function call |
| S004 | Security | Dangerous shell pattern |
| S005 | Security | Secret pattern in string value |

---

## Security Rules (MANDATORY)

1. **Never hardcode API keys** — read from environment variables at runtime
2. **Always sanitize file paths** — use `sanitize_path(user_input)`
3. **Use `SecureAgent`** instead of `Agent` in production (has prompt injection detection)
4. **Enable sandbox** for untrusted code execution
5. **Run `panther check`** — security diagnostics (S001-S005) run during linting

---

## CLI Commands

```bash
panther run <file>              # Execute .panther/.pan file
panther run --serve <file>      # Execute with HTTP server
panther build <file>            # Build to shell artifact
panther check <file>            # Syntax validation (no execution)
panther fmt <file>              # Validate and print formatted source
panther new console <name>      # Scaffold console project
panther new web <name>          # Scaffold web project
panther new api <name>          # Scaffold API project
panther new ai <name>           # Scaffold AI project
panther doctor                  # Verify all 11 system components
panther version                 # Show version info
panther help                    # Print command summary
```

---

## Project Structure

```
my-project/
├── panther.toml          # Project manifest
├── README.md
├── .gitignore
├── src/
│   └── main.panther      # Entry point
├── tests/                # Test files
├── docs/                 # Documentation
└── .vscode/              # VS Code config
    ├── settings.json
    ├── tasks.json
    └── launch.json
```

### panther.toml (Minimal)

```toml
[project]
name = "my-project"
type = "console"   # console, web, api, ai
version = "0.1.0"
language = "panther"

[run]
main = "src/main.panther"
```

---

## AI Platform (Python API)

```python
# Providers (all support mock mode without API keys)
from compiler.ai.providers import (
    OpenAIProvider,      # OPENAI_API_KEY
    AnthropicProvider,   # ANTHROPIC_API_KEY
    GeminiProvider,      # GEMINI_API_KEY
    OllamaProvider,      # Local, no key needed
    OpenRouterProvider,  # OPENROUTER_API_KEY
)

# Agents
from compiler.ai.agents import Agent
from compiler.ai.secure_agent import SecureAgent

agent = SecureAgent("assistant")
agent.register_tool("get_weather", weather_fn)
response = agent.complete(user_input)  # Injection detection + audit

# RAG
from compiler.ai.rag import RAGEngine
engine = RAGEngine(embedding_provider)
engine.add_document("PantherLang is a programming language.")
results = engine.query("What is PantherLang?", top_k=3)
```

---

## Web Platform (Python API)

```python
from compiler.web.server import HttpServer
from compiler.web.security import (
    SecurityHeaders, CSRFProtection, RateLimiter,
    CORSValidator, SecureRequestHandler
)

server = HttpServer(host="0.0.0.0", port=8080)
server.get("/", lambda req: {"message": "Hello!"})
server.post("/api", lambda req: {"received": req.body})

# Add security middleware
handler = SecureRequestHandler()
server.use(handler)
server.start()
```

---

## Database (SQLite)

### PantherLang Stdlib
```panther
let conn = db_open(":memory:");
db_execute(conn, "CREATE TABLE users (id INTEGER, name TEXT)");
db_execute(conn, "INSERT INTO users VALUES (1, 'Alice')");
let rows = db_query(conn, "SELECT * FROM users");
print rows[0]["name"];  // "Alice"
db_close(conn);
```

### Python ORM
```python
from compiler.database.orm import SqliteEngine, Model, Column

engine = SqliteEngine(":memory:")
class User(Model):
    name = Column(str)
    age = Column(int)

engine.create_table(User)
user = User(name="Alice", age=30)
engine.insert(user)
```

---

## Verification Commands

```bash
# Full test suite (1039+ tests)
python -m pytest

# Single test file
python -m pytest tests/security/test_web_security.py -v

# Example tests
python -m pytest tests/test_examples.py -v

# Run all examples
bash scripts/run_examples.sh

# Syntax check
panther check src/main.panther

# System health
panther doctor

# Build package
python -m build
```

---

## Key Files for AI Agents

| File | Purpose |
|------|---------|
| `AGENTS.md` | Quick reference for AI agents |
| `docs/agent_knowledge/PANTHERLANG_AGENT_GUIDE.md` | How to work in PantherLang projects |
| `docs/agent_knowledge/PANTHERLANG_GRAMMAR_QUICK_REFERENCE.md` | Syntax cheat sheet |
| `docs/agent_knowledge/PANTHERLANG_PROJECT_CONVENTIONS.md` | Project layout standards |
| `docs/book/chapters/14-language-reference.md` | Complete language reference |
| `docs/book/chapters/07-standard-library.md` | Stdlib API reference |
| `docs/specification/` | 8 formal specification documents |
| `examples/` | 11 verified working examples |

---

## Version Notes for v1.1.5

- **Comparison semantics:** Strict equality with descriptive errors (PDL-005)
- **All 1039 tests pass** with 0 failures
- **11/11 examples pass**
- **4/4 project templates** create and run
- **VS Code extension v1.1.5** with debug adapter v1.1.5
- **Package builds:** `pantherlang-1.1.5.tar.gz` and `pantherlang-1.1.5-py3-none-any.whl`

---

## Sources

This knowledge pack consolidates information from:
- `AGENTS.md`
- `docs/agent_knowledge/` (4 files)
- `docs/book/` (15 chapters)
- `docs/specification/` (8 formal specs)
- `docs/academy/` (Academy status)
- `docs/cookbook/` (Cookbook roadmap)
- `compiler/` (source implementation)
- `tests/` (1039+ test cases)
- `examples/` (11 verified programs)

---

*Generated for PantherLang v1.1.5 Public Release — 2026-07-04*