# Lab 05: Type Conversions & IO

## Objectives
- Convert between types using `int()`, `float()`, and `string()`
- Parse structured text into typed variables
- Handle edge cases in type conversion

## Theory

PantherLang provides explicit conversion functions:
- `int(value)` — converts to integer (works with strings like `"42"` and floats like `3.14`)
- `float(value)` — converts to float (works with strings like `"3.14"` and integers)
- `string(value)` — converts any value to its string representation

The `type_of(value)` function returns the type name as a string (e.g., `"int"`, `"float"`, `"string"`).

## Exercises

### Exercise 1: Parse a CSV-like Line
**Task**: Given a string `"42,3.14,hello"`, split it conceptually into parts and convert each part to its appropriate type. Store the int `42`, the float `3.14`, and the string `"hello"` in separate variables. Print each with a label and its type.

**Hint**: Hard-code the three parts as separate string variables, then convert: `let a = int("42"); let b = float("3.14"); let c = "hello";`. Use `type_of()` to verify types.

**Verify**: The output should show each value and its type, e.g., `42 (int)`, `3.14 (float)`, `hello (string)`.

### Exercise 2: Temperature Conversion
**Task**: Given a temperature string `"98.6F"`, extract the numeric part `98.6` as a float, then convert it to Celsius using the formula `C = (F - 32) * 5 / 9`. Print the result.

**Hint**: Parse the numeric part with `float("98.6")`. Use `string()` to build the output message: `print string(celsius) + "C"`.

**Verify**: `98.6F` converts to approximately `37.0C`.

### Exercise 3: Safe Conversion — Edge Cases
**Task**: Try these conversions and observe the results:
- `float("12.5")` — what happens with a decimal string converted to float?
- `int("42")` — straightforward integer conversion
- `string(null)` — what does null look like as a string?
- `string(true)` — what does a boolean look like as a string?
- `type_of("42")` vs `type_of(42)` — what types are detected?

**Hint**: Use `print` on each conversion. `type_of()` tells you the runtime type.

**Verify**: Observe the outputs: `12.5`, `42`, `"null"`, `"true"`, `"string"`, `"int"`.

## Summary
You practiced explicit type conversion with `int()`, `float()`, and `string()`, and explored how PantherLang handles edge cases during parsing.

## Further Reading
- Academy Lesson 05: Type Conversions
- Book Chapter 06: Working with Data
