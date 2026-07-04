# PantherLang Type System Specification

## Primitive Types

| Type | Name | Values | Example |
|------|------|--------|---------|
| int | `int` | 64-bit signed integers | `42`, `-7` |
| float | `float` | 64-bit IEEE 754 floats | `3.14`, `-0.5` |
| string | `string` | UTF-8 encoded text | `"hello"` |
| bool | `bool` | Boolean | `true`, `false` |
| null | `null` | Single null value | `null` |
| any | `any` | Any type (top type) | - |

## Type Annotations

Variables can be declared with explicit type annotations:

```
let x: int = 42;
let name: string = "Panther";
let flag: bool = true;
```

## Type Inference

When no type annotation is provided, the type is inferred from the initializer:

```
let x = 42;       // x: int
let y = 3.14;     // y: float
let s = "hello";  // s: string
```

## Assignment Compatibility Rules

| Value Type | Can Assign To |
|------------|---------------|
| int | int, float, any |
| float | float, any |
| string | string, any |
| bool | bool, any |
| null | null, any |
| any | any type |

## Type Checking

The type checker validates:

1. **Variable declarations**: initializer type must match declared type
2. **Assignments**: value type must be compatible with variable type
3. **Function returns**: return value must match declared return type
4. **Operator operands**: operands must be valid for the operator (e.g., `&&` requires bool)

## Diagnostics

Type errors produce diagnostic code `T001` with a descriptive message.

## Implementation Status

- Type checking runs during semantic analysis
- Type annotations are parsed and checked but not enforced at runtime
- Arrays and objects have type `any` (no generic type parameters yet)
