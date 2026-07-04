# PantherLang Keywords

## Reserved Keywords (30)

| Keyword | Context | Description |
|---------|---------|-------------|
| `panther` | Top-level | Introduces a `panther main { }` entry block |
| `main` | Top-level | Marks the program entry point block |
| `web` | Top-level | Marks a web block (route definitions) |
| `api` | Top-level | Marks an API block (route definitions) |
| `ai` | Top-level | Marks an AI provider configuration block |
| `test` | Top-level | Marks a test block |
| `let` | Statement | Declares a variable |
| `fn` | Statement | Declares a function |
| `return` | Statement | Returns a value from a function |
| `if` | Statement | Conditional branch |
| `elif` | Statement | Else-if branch |
| `else` | Statement | Else branch |
| `while` | Statement | While loop |
| `for` | Statement | For-range loop |
| `in` | Expression | Range separator in `for i in 1..10` |
| `loop` | Statement | Infinite loop |
| `break` | Statement | Exit a loop |
| `continue` | Statement | Skip to next loop iteration |
| `struct` | Statement | Declare a struct type |
| `enum` | Statement | Declare an enum type |
| `trait` | Statement | Declare a trait (interface) |
| `import` | Statement | Import a module |
| `print` | Statement | Print a value |
| `route` | Statement | Register an HTTP route |
| `get` | Route | GET method for route |
| `post` | Route | POST method for route |
| `put` | Route | PUT method for route |
| `delete` | Route | DELETE method for route |
| `as` | Import | Module alias (`import foo as bar`) |
| `true` | Literal | Boolean true |
| `false` | Literal | Boolean false |
| `null` | Literal | Null value |

## Contextual Keywords

The following words are parsed as identifiers in most contexts but serve as
keywords in specific positions:

- `get`, `post`, `put`, `delete` — route method specifiers
- `in` — range separator in `for` loops
- `as` — import alias
