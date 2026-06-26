# PantherLang Official Language Specification — Phase 1.8

## Status
Draft locked for Developer Preview.

## Identity
PantherLang is an independent, AI-native programming language designed to build complete software systems from one source of truth.

PantherLang is:
- a language
- a compiler pipeline
- a runtime model
- the foundation of Panther Platform

PantherLang is not:
- a Python wrapper
- a framework only
- a temporary DSL
- a code-generation trick

## Design Covenant
Every PantherLang feature must satisfy these questions:

1. Does it make the language simpler?
2. Does it make the language safer?
3. Does it make the language clearer for humans?
4. Does it make the language easier for AI systems?
5. Will it still be understandable after ten years?

## Source Files
PantherLang files use:

```text
.panther
```

## Official Command
The future official command:

```bash
panther
```

Current prototype command:

```bash
python3 panther.py
```

## Program Structure

A Panther program is built from semantic blocks:

```panther
app PantherStore {
    version "0.5"
}

model Product {
    id: uuid
    title: string required
    price: decimal required
}

api GET /products {
    public
    return Product.all()
}

page Products {
    title "Products"
    table Product
}
```

## Reserved Keywords

```text
app module package import from as
let var const readonly immutable
fn return yield
if else match case
for while break continue
try catch throw error result
type model entity struct enum interface impl
data api page ui workflow agent task event state service
async await parallel channel
capabilities allow deny security policy permission secret
deploy target runtime config
true false null none void
```

## Primitive Types

```text
int
float
decimal
bool
string
char
bytes
uuid
date
time
datetime
duration
json
any
void
```

## Collection Types

```text
list<T>
array<T>
map<K,V>
set<T>
tuple<T...>
```

## Advanced Types

```text
optional<T>
result<T,E>
future<T>
stream<T>
```

## Nullable Types

```panther
User?
Product?
Order?
```

Values are non-null by default. Nullable values must be explicit.

## Naming Rules

| Item | Rule | Example |
|---|---|---|
| App | PascalCase | PantherStore |
| Model | PascalCase | Product |
| Field | snake_case | created_at |
| Function | snake_case | calculate_total |
| Package | lowercase.dot.path | panther.http |
| File | snake_case.panther | product_service.panther |

## Models

Models define semantic data entities.

```panther
model Product {
    id: uuid
    title: string required
    price: decimal required
    stock: int = 0
}
```

Rules:
- Model names use PascalCase.
- Fields use snake_case.
- Money uses decimal.
- Required fields must be declared.
- Nullability must be explicit.

## APIs

```panther
api GET /products {
    public
    return Product.all()
}

api POST /products {
    public
    create Product from request.body
}
```

Rules:
- API methods must be explicit.
- Input must be typed.
- Public access must be declared.
- Secure endpoints must declare policy.

## UI Pages

```panther
page Products {
    title "Products"
    table Product
}
```

Rules:
- UI declarations describe intent.
- Runtime decides implementation.
- Future Panther Studio will read this layer.

## Workflows

```panther
workflow LowStock {
    when Product.stock < 5 {
        notify admin "Low stock"
    }
}
```

## Agents

```panther
agent InventoryAI {
    purpose "Monitor stock and recommend actions"
    tools data, api
    memory scoped
}
```

Rules:
- Agent purpose must be explicit.
- Tools must be declared.
- Memory scope must be declared.
- Dangerous actions require capabilities.

## Security

PantherLang is deny-by-default.

```panther
capabilities {
    network allow local
    filesystem allow app_storage
    ai allow scoped
}
```

Rules:
- Network access must be declared.
- Filesystem access must be declared.
- Secrets cannot be printed.
- Dangerous commands require explicit permission.

## Error Handling

PantherLang prefers explicit result types:

```panther
fn load_user(id: uuid) -> result<User, UserError>
```

## AI-Native Requirements

PantherLang must be easy for AI systems to:
- read
- write
- refactor
- explain
- validate
- convert to other languages
- convert from other languages

## Phase 1 Completion Target

Phase 1 is complete when PantherLang has:

- Language Specification
- Lexer
- Parser
- AST
- Semantic Engine
- Type System
- IR
- Code Generator
- First Compiler
- Tests
- Developer Preview Documentation
