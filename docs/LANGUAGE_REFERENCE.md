# PantherLang Language Reference

## File Extensions

- `.panther` — Primary extension
- `.pan` — Alternative extension

## Program Structure

A PantherLang program consists of statements and expressions.

## Types

| Type | Description | Example |
|------|-------------|---------|
| `int` | Integer numbers | `42`, `-7` |
| `float` | Floating-point numbers | `3.14`, `-0.5` |
| `string` | Text strings | `"hello"` |
| `bool` | Boolean values | `true`, `false` |
| `null` | Null value | `null` |
| `any` | Any type | Dynamic typing |

## Variables

```panther
let x: int = 42
let name: string = "PantherLang"
let flag = true  # type inferred
```

## Control Flow

```panther
if x > 0 {
    print "positive"
} elif x == 0 {
    print "zero"
} else {
    print "negative"
}
```

## Loops

```panther
# While loop
while x > 0 {
    x = x - 1
}

# For loop
for i in 1..5 {
    print i
}
```

## Functions

```panther
fn add(a: int, b: int) -> int {
    return a + b
}
```

## Structs

```panther
struct Point {
    x: int
    y: int
}

let p = Point(1, 2)
print p.x
```

## Enums

```panther
enum Color {
    Red
    Green
    Blue
}
```

## Traits

```panther
trait Printable {
    fn print(self)
}
```

## Standard Library

```panther
# String operations
len("hello")         # 5
upper("hello")       # "HELLO"
contains("hello", "ell")  # true

# Math operations
abs(-5)              # 5
sqrt(16)             # 4.0
random()             # 0.0..1.0

# JSON
json_encode({"key": "value"})
json_decode('{"key": "value"}')

# Crypto
sha256("data")
secure_token(32)

# Path security
sanitize_path("/base", "user/input")
sanitize_html("<script>alert(1)</script>")
```

## Web Platform

```panther
route "/" {
    return "Hello World"
}
```

## Database

```panther
table users {
    id: int primary_key
    name: string
}
```

## AI

```panther
prompt = "What is PantherLang?"
# AI providers available via OpenAI, Anthropic, Gemini, Ollama, OpenRouter
