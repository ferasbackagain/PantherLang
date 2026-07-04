# PantherLang Runtime Specification

## Execution Model

PantherLang programs execute through a tree-walking interpreter:

```
Source → Lexer → Parser → AST → Statement Executor → Output
```

## Variable Environment

Variables are stored in a scoped `VariableEnvironment`:

- Each scope has its own `_variables` dict
- Child scopes inherit from parent scopes
- `let` declares a new variable in the current scope
- Assignment (`=`) finds the variable in the current or parent scope
- Function calls create a new child scope

## Function Calls

Functions are first-class closures stored in the environment:

1. `fn add(a, b) { return a + b; }` creates a closure
2. `add(3, 4)` evaluates `add` to the closure, evaluates `3` and `4`, calls the closure
3. Each call creates a new child scope with parameters bound to argument values
4. `return` exits the function with a value; missing `return` returns `null`

## Control Flow

| Construct | Behavior |
|-----------|----------|
| `if` | Evaluate condition, execute matching branch |
| `while` | Evaluate condition before each iteration |
| `for i in 1..5` | Iterate `i` from `start` to `end` (inclusive) |
| `loop` | Infinite `while true` |
| `break` | Exit innermost loop via exception |
| `continue` | Skip to next iteration via exception |

## Standard Library Integration

Stdlib functions are registered at startup via `VariableEnvironment.create_default()`:

```
compiler.stdlib.functions._STDLIB  →  env._functions
```

Each stdlib function is a Python callable stored in the function registry.

## HTTP Server Mode

`serve_source()` executes source and starts an HTTP server:
1. Parse and execute PantherLang source
2. Route statements register handlers with an `HttpServer`
3. Server listens on `0.0.0.0:8080` by default
4. Handlers execute route body statements per request

## Error Handling

Runtime errors produce `ExecutionResult.error` as a string message:

| Error Type | Description |
|------------|-------------|
| Parse error | Invalid syntax |
| Undefined variable | Variable not in scope |
| Redeclaration | `let` on existing variable |
| Type error | Invalid operand types |
| Index out of range | Array index beyond length |
| Unsupported expression | Expression type not implemented |
