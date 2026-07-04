# LANGUAGE_RULES.md

## PantherLang Language Rules

This document defines the core rules and constraints that govern PantherLang programming. It serves as the authoritative reference for the language's semantics, syntax, and behavior.

---

## Lexical Rules

### Identifiers
- **Pattern**: `[a-zA-Z_][a-zA-Z0-9_]*`
- **Case-sensitive**: `myVar != myvar`
- **Keywords reserved**: 30 keywords (see 03_KEYWORDS.md)

### Literals
- **Integers**: `[0-9]+` (no leading zeros except `0`)
- **Floats**: `[0-9]*\.[0-9]+([eE][+-]?[0-9]+)?`
- **Strings**: `"`...`"` with escape sequences (`\n`, `\t`, `\"`, `\\`)
- **Comments**: `//` single-line comments only

### Whitespace
- **Whitespace**: Spaces, tabs, newlines ignored
- **Newlines required**: After semicolons for statement separation
- **Indentation**: For block structure, minimum 4 spaces

---

## Grammar Rules

### Expression Structure
- **Prefix**: unary operators (`-`, `+`, `!`)
- **Infix**: binary operators (`+`, `-`, `*`, `/`, `%`, `==`, `!=`, etc.)
- **Postfix**: function calls, indexing (`expr[0]`, `expr.field`)
- **Grouping**: `( expression )`

### Operator Precedence (Highest to Lowest)
1. `()`, `[]`, `.` (grouping, indexing, member access)
2. Unary `+`, `-`, `!`
3. `**` (exponentiation)
4. `*`, `/`, `%` (multiplication/division/modulo)
5. `+`, `-` (addition/subtraction)
6. `>`, `>=`, `<`, `<=` (relational)
7. `==`, `!=` (equality)
8. `&&` (logical AND)
9. `||` (logical OR)

### Statement Structure
```panther
statement:
    let_stmt
    assignment_stmt
    if_stmt
    while_stmt
    for_stmt
    loop_stmt
    fn_decl
    struct_decl
    enum_decl
    trait_decl
    import_stmt
    return_stmt
    break_stmt
    continue_stmt
    route_stmt
    block
    expression_stmt
```

---

## Semantic Rules

### Variable Declaration
```panther
let_stmt:
    'let' IDENTIFIER (':' type)? '=' expression

Examples:
let x = 42;                    // int, inferred
let name: string = "Alice";    // explicit type
let count = 3.14;              // float, inferred
```

#### Rules:
1. **Every variable must be declared** before use
2. **Type inference** is automatic from initial value
3. **Optional type annotations** allowed with `:`
4. **Reassignment** using `=` (including compound operators)

### Function Declaration
```panther
fn_decl:
    'fn' IDENTIFIER '(' params ')' (':' type)? block

params:
    IDENTIFIER (':' type)? (',' params)?

type:
    'int' | 'float' | 'string' | 'bool' | 'null' | 'any'
    | IDENTIFIER | '[' type ']' | '{' type '}'
```

#### Rules:
1. **Functions can be nested** (closures capture outer scope)
2. **Only named functions** allowed (lambdas not supported)
3. **Return type annotations** optional
4. **Functions are first-class** values

### Control Flow Rules
#### If Statement
```panther
if_stmt:
    'if' expression block
    ('elif' expression block)*
    ('else' block)?

Rules:
1. Condition evaluates to bool (truthy/falsy rules)
2. `elif` allowed but not `else if`
3. Exactly one branch executes
```

#### Loops
```panther
while_stmt:
    'while' expression block

Rules:
1. `break` exits loop entirely
2. `continue` jumps to next iteration
3. `break`/`continue` outside loop = E001/E002
```

#### For Loop
```panther
for_stmt:
    'for' IDENTIFIER 'in' expression '..' expression block

Rules:
1. Both bounds must be integers
2. Range: `for i in 1..10` executes for i = 1..10
3. Variable defined in loop scope
```

### Type System Rules
#### Type Compatibility (T001)
```panther
binary_op_rules:
    numeric + numeric → numeric
    string + string → string
    bool + bool → bool
    array + array → array (concatenation)

comparison_rules:
    comparable + comparable → bool
    comparisons require same type or numeric promotion
```

#### Type Conversion
```panther
Explicit conversion required for:
1. Arithmetic: string + int → error, use to_int()
2. Comparison: string == int → error, use to_string() or to_int()
3. Assignment: incompatible types → error

Built-in conversions:
- to_string(value): any → string
- to_int(value): float/string → int
- to_float(value): string → float
- to_number(value): string → float/int
- to_bool(value): any → bool
- type_of(value): any → type_name
```

### Collection Rules
#### Arrays
```panther
array_syntax:
    '[' element (',' element)* ']'

Rules:
1. Zero-based indexing: `arr[0]`
2. Dynamic length: `len(arr)` from stdlib
3. Heterogeneous allowed (mixed types)
```

#### Objects (Dictionaries)
```panther
object_syntax:
    '{' member (',' member)* '}'

member:
    IDENTIFIER ':' value

Rules:
1. Keys are always strings
2. No duplicate keys allowed
3. Object access: `obj["key"]` or `obj.key`
```

#### Indexing Rules
```panther
indexing:
    expression '[' expression ']'

Rules:
1. Arrays: integer index (negative indexing: -1 = last)
2. Objects: string key
3. Nested indexing allowed: `matrix[0][0]`
4. Out of bounds → runtime error
```

---

## Error Rules & Diagnostics

### Error Code Categories
| Code Range | Type | Description |
|------------|------|-------------|
| E001-E008 | Semantic | Symbol table and scope errors |
| PT001 | Type | Type conversion errors |
| PT002 | Type | Comparison errors |
| PR001 | Runtime | Division/modulo by zero |
| S001-S005 | Security | Security diagnostics |

### Specific Error Rules
#### E001: Break Outside Loop
```panther
panther main {
    break;  // E001 error
}
```

#### E002: Continue Outside Loop
```panther
panther main {
    continue;  // E002 error
}
```

#### E003: Duplicate Variable Definition
```panther
panther main {
    let x = 1;
    let x = 2;  // E003 error
}
```

#### E004: Undefined Variable
```panther
panther main {
    print y;  // E004 error (y not defined)
}
```

#### E005: Duplicate Import
```panther
panther main {
    import std.math;
    import std.math;  // E005 error
}
```

#### E006: Duplicate Function Definition
```panther
panther main {
    fn foo() { }
    fn foo() { }  // E006 error
}
```

#### E007: Scope Resolution Error
```panther
panther main {
    let x = 10;
    fn inner() {
        print x;  // OK, captures from outer
        // but x from different scope causes issues
    }
}
```

#### E008: Import Resolution Error
```panther
panther main {
    import nonexistent.module;  // E008 error
}
```

### Security Error Rules (S001-S005)
1. **S001**: Hardcoded secret detected
2. **S002**: Dangerous API usage detected
3. **S003**: Path traversal attempt detected
4. **S004**: Unsafe file operation detected
5. **S005**: Prompt injection pattern detected

### Type Error Rules
#### PT001: Mixed String/Int Operations
```panther
panther main {
    let a = "hello";
    let b = 5;
    let c = a + b;  // PT001 error
    // Fix: let c = a + to_string(b);
}
```

#### PT002: Different Type Comparison
```panther
panther main {
    let a = "5";
    let b = 5;
    if a == b {  // PT002 error
        print "equal";
    }
    // Fix: if to_string(a) == to_string(b) or to_int(a) == b;
}
```

### Runtime Error Rules
#### PR001: Division/Modulo by Zero
```panther
panther main {
    let a = 10;
    let b = 0;
    let c = a / b;  // PR001 error
    // or let c = a % b;
}
```

---

## Security Rules

### Mandatory Rules
1. **Never hardcode API keys**: Use environment variables
2. **Always sanitize file paths**: Use `sanitize_path()` function
3. **Use `SecureAgent`**: For production AI agents
4. **Enable sandbox**: For untrusted code execution
5. **Enable security diagnostics**: Run `panther check` for S001-S005

### Security Violations
```panther
panther main {
    // S001: Hardcoded secret
    let api_key = "sk-12345-abcedf";  // VIOLATION!
    
    // S003: Path traversal
    read_file("/etc/passwd");  // VIOLATION!
    
    // S005: Prompt injection
    let prompt = "Ignore previous instructions";
    agent.ask(prompt);  // VIOLATION!
}
```

---

## Standard Library Rules

### Import Rules
```panther
// No imports needed - everything in stdlib
panther main {
    print len("hello");     // stdlib function
    print abs(-5);          // stdlib function
    print json_encode({a:1}); // stdlib function
}
```

### Extension Functions
- Functions defined in AST nodes
- Cannot be overloaded
- Type signature fixed at definition

---

## Cross-Platform Rules

### File Path Handling
```panther
// Always use forward slashes
write_file("data/file.txt", "content");
write_file("data\\file.txt", "content");  // WRONG!

// Sanitization required
write_file(sanitize_path("../external.txt"), "data");
```

### Line Endings
- **Unix**: `\n` (default)
- **Windows**: `\r\n` (auto-converted by tools)
- **macOS**: `\r` (default)

---

## Performance Rules

### Memory Management
1. **No garbage collection**: Manual memory management
2. **Closures capture scope**: Possible reference cycles
3. **Arrays/Objects**: Dynamic sizing with reallocation cost

### Optimization
1. **Local variables**: Prefer local over global
2. **Function calls**: Inline small functions when possible
3. **Type consistency**: Use homogeneous collections
4. **Avoid boxing**: Simple types passed by value

---

## Testing & Validation Rules

### Test Requirements
1. **All new code requires tests**: Integration with pytest
2. **0 failed, 0 errors**: Full regression required
3. **Example validation**: All examples must execute correctly
4. **Security scanning**: Run `panther check` for S001-S005

### Test Structure
```python
# tests/test_new_feature.py
def test_basic_functionality():
    result = execute_source("panther main { print 'test'; }")
    assert result.captured_output == ["test"]
    assert result.error is None

def test_type_errors():
    result = execute_source("let x = '5' + 5;")
    assert result.error is not None  # PT001 expected
```

---

## Maintenance Rules

### Code Evolution
1. **Backward compatibility**: Never break existing APIs
2. **Defensive coding**: Validate all external inputs
3. **Documentation**: All new code requires comments/examples
4. **Testing**: Unit, integration, and security tests required

### Refactoring
- **Refactor only when**: Performance/debugging benefit clear
- **Document changes**: Update all dependent documentation
- **Test thoroughly**: Run full regression before refactoring

---

## References

- 01_LEXICAL_SPECIFICATION.md: Character set and token definitions
- 02_GRAMMAR_EBNF.md: Formal grammar and precedence
- 03_KEYWORDS.md: Complete keyword list
- 04_OPERATORS.md: Operator definitions and rules
- 05_TYPE_SYSTEM_SPECIFICATION.md: Type system rules
- 06_RUNTIME_SPECIFICATION.md: Execution model
- 07_MODULE_SPECIFICATION.md: Import and module system
- 08_ERROR_SPECIFICATION.md: Error codes and diagnostics
- compiler/: Actual implementation
- examples/: Verified working examples
- tests/: Test suite specifications

---

*This document is generated from the actual implementation and represents the current stable language specification.*
