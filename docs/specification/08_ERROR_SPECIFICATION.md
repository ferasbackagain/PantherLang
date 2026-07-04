# PantherLang Error Specification

## Error Codes

### Semantic Errors (E001–E008)

| Code | Message | Cause |
|------|---------|-------|
| E001 | `'break' outside loop` | `break` used outside a loop context |
| E002 | `'continue' outside loop` | `continue` used outside a loop context |
| E003 | Redeclaration error | Variable redeclared in same scope |
| E004 | Function declaration error | Invalid function declaration |
| E005 | `Duplicate type '{name}'` | Type with same name already declared |
| E006 | Module import error | Module import failed |
| E007 | `Undefined variable '{name}'` | Assignment to undeclared variable |
| E008 | `Undefined symbol '{name}'` | Reference to undeclared symbol |

### Type Errors (T001)

| Code | Message | Cause |
|------|---------|-------|
| T001 | Type mismatch errors | Various type incompatibility conditions |

### Security Diagnostics (S001–S005)

| Code | Message | Cause |
|------|---------|-------|
| S001 | `Hardcoded secret detected` | `api_key`, `password`, `secret`, `token` in value |
| S002 | `Hardcoded credential pattern` | Credential-like literal in assignment |
| S003 | `Potentially dangerous API call` | `eval`, `exec`, `__import__` used |
| S004 | `Dangerous shell pattern detected` | Shell metacharacters in string |
| S005 | `Hardcoded sensitive default` | Sensitive default in variable |

### Parser Diagnostics

| Token | Error |
|-------|-------|
| Any | `Expected '{kind}' after '{context}'` |
| Any | `Expected expression, got {lexeme}` |
| Any | `Unterminated delimiter; expected '{matching}'` |

### Runtime Errors

| Error | Message Pattern |
|-------|-----------------|
| Parse error | `Parse error: {diagnostic}` |
| Undefined variable | `Undefined variable: {name}` |
| Redeclaration | `Variable already declared: {name}` |
| Type error | `Type error in {operation}: {detail}` |
| Index out of range | `Array index {i} out of range (length {n})` |
| Object key missing | `Object has no key '{key}'` |
| Not indexable | `Cannot index into {type}` |
| Unsupported expression | `Unsupported expression: {type}` |
| Unsupported statement | `Unsupported statement: {type}` |
