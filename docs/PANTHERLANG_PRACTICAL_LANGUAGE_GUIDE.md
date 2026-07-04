# PantherLang Practical Language Guide

## What Works Now

PantherLang is a working, executable programming language. This guide covers
everything you can do with it today.

---

## 1. Project Structure

A PantherLang project has a `panther main { }` block as entry point:

```panther
panther main {
    print "Hello, PantherLang";
}
```

Save as `main.pan` or `main.panther`, then run:

```bash
panther run main.pan
```

## 2. Variables

Use `let` to declare variables. Type is inferred from the initializer:

```panther
let name = "PantherLang";
let year = 2026;
let pi = 3.14;
let is_active = true;
let nothing = null;
```

## 3. Literals

| Type | Examples |
|------|----------|
| Integer | `42`, `-7`, `0` |
| Float | `3.14`, `-0.5` |
| String | `"hello"`, `"42"` |
| Boolean | `true`, `false` |
| Null | `null` |

## 4. Expressions

Arithmetic: `+`, `-`, `*`, `/` (integer division), `%`, `**` (power)

Comparison: `==`, `!=`, `>`, `>=`, `<`, `<=`

Logical: `&&` (and), `||` (or), `!` (not)

```panther
let result = (10 + 5) * 2;
let is_equal = (result == 30);
```

## 5. Assignment

Reassign variables with `=`:

```panther
let x = 10;
x = x + 5;
```

Compound assignment: `+=`, `-=`, `*=`, `/=`, `%=`

## 6. Functions

Define functions with `fn`:

```panther
fn add(a, b) {
    return a + b;
}

let sum = add(3, 4);
```

Functions support recursion:

```panther
fn factorial(n) {
    if n <= 1 {
        return 1;
    }
    return n * factorial(n - 1);
}
```

## 7. Control Flow

### if / elif / else

```panther
let x = 42;
if x > 0 {
    print "positive";
} elif x == 0 {
    print "zero";
} else {
    print "negative";
}
```

### while loop

```panther
let i = 0;
while i < 5 {
    print i;
    i = i + 1;
}
```

### for loop

```panther
for i in 1..5 {
    print i;
}
```

### break / continue

```panther
let i = 0;
while i < 10 {
    i = i + 1;
    if i == 3 {
        continue;
    }
    if i == 7 {
        break;
    }
    print i;
}
```

## 8. Structs, Enums, Traits

```panther
struct Point {
    x: int
    y: int
}

let p = Point(10, 20);
print p.x;  // 10

enum Color {
    Red
    Green
    Blue
}

trait Printable {
    fn print(self)
}
```

## 9. Standard Library

### String functions
| Function | Description |
|----------|-------------|
| `len(s)` | String length |
| `upper(s)` | Uppercase |
| `lower(s)` | Lowercase |
| `trim(s)` | Strip whitespace |
| `contains(s, sub)` | Check substring |
| `replace(s, old, new)` | Replace substring |
| `substring(s, start, end)` | Slice string |
| `split(s, sep)` | Split string |
| `starts_with(s, prefix)` | Prefix check |
| `ends_with(s, suffix)` | Suffix check |
| `join(sep, items)` | Join strings |

### Math functions
| Function | Description |
|----------|-------------|
| `abs(x)` | Absolute value |
| `max(a, b, ...)` | Maximum |
| `min(a, b, ...)` | Minimum |
| `pow(x, y)` | Power |
| `sqrt(x)` | Square root |
| `floor(x)` | Floor |
| `ceil(x)` | Ceil |
| `round(x, n)` | Round |
| `random()` | Random float [0, 1) |
| `randint(lo, hi)` | Random integer |

### JSON
| Function | Description |
|----------|-------------|
| `json_encode(obj)` | Object to JSON string |
| `json_decode(s)` | JSON string to object |

### Time
| Function | Description |
|----------|-------------|
| `time()` | Current Unix timestamp |
| `sleep(secs)` | Sleep for seconds |

### Type Conversion
| Function | Description |
|----------|-------------|
| `int(x)` | Convert to integer |
| `float(x)` | Convert to float |
| `string(x)` | Convert to string |

### Crypto (Security)
| Function | Description |
|----------|-------------|
| `sha256(data)` | SHA-256 hash |
| `hmac_sha256(key, msg)` | HMAC-SHA256 |
| `secure_token(n)` | Random hex token |
| `secure_compare(a, b)` | Timing-safe compare |
| `sanitize_path(base, path)` | Path traversal prevention |
| `sanitize_html(text)` | HTML entity encoding |

## 10. Project Templates

```bash
panther new console myapp   # Console application
panther new web myapp       # Web application
panther new api myapp       # API application
panther new ai myapp        # AI application
```

## 11. Current Limitations

| Area | Limitation |
|------|------------|
| Array/List | Not yet supported as literal values |
| Dict/Object | Not yet supported as literal values |
| Web runtime | Template structure exists; HTTP server available via Python API |
| API runtime | Template structure exists; no native route dispatch |
| AI runtime | Template structure exists; providers available via Python API |
| Module imports | Basic module system exists |
| Error messages | Parse errors are technical; being improved |
| Type annotations | Parsed but not enforced at runtime |

## 12. Next Language Roadmap

1. Array and dictionary literals
2. Native web/API/AI runtime execution
3. Better error messages with source snippets
4. Module import resolution
5. Package registry integration
6. Formatter (auto-indent, style)
7. LSP integration for IDE support
8. Standard library expansion

## Resources

- GitHub: https://github.com/ferasbackagain/PantherLang
- CLI: `panther help`
- Examples: `examples/` directory
- Docs: `docs/` directory
