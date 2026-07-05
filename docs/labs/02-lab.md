# Lab 02: Variables & Types

## Objectives
- Declare variables with `let` using type inference
- Understand PantherLang's primitive types: int, float, string, bool, null
- Convert between types using `int()`, `float()`, and `string()`

## Theory

Use `let name = value` to declare a variable. PantherLang infers the type from the value. The primitive types are:
- **int**: whole numbers (`42`, `-7`)
- **float**: decimal numbers (`3.14`, `-0.5`)
- **string**: text (`"hello"`)
- **bool**: boolean (`true`, `false`)
- **null**: absence of value (`null`)

Convert between types using built-in functions: `int("42")` → `42`, `string(42)` → `"42"`, `float("3.14")` → `3.14`.

## Exercises

### Exercise 1: Declare Every Type
**Task**: Create one variable for each primitive type: an int, a float, a string, a bool, and null. Print each one.

**Hint**: Use `let x = 10`, `let pi = 3.14`, `let name = "Panther"`, `let flag = true`, `let nothing = null`. Print each on its own line.

**Verify**: Run the solution file — you should see five lines of output (number, decimal, text, true, null).

### Exercise 2: Parse and Compute
**Task**: Convert the string `"42"` to an int using `int()`, then add `8` and print the result.

**Hint**: `let val = int("42"); print val + 8` → outputs `50`.

**Verify**: The output should be `50`.

### Exercise 3: Null as String
**Task**: Convert `null` to a string using `string()` and print it. Then print `null` directly to see the difference.

**Hint**: `print string(null)` prints the string `"null"`; `print null` prints the value `null`.

**Verify**: Both lines should show some form of `null` — the first as a string, the second as the literal value.

## Summary
You learned how to declare variables of all primitive types and convert between them using `int()`, `float()`, and `string()`.

## Further Reading
- Academy Lesson 02: Variables
- Academy Lesson 05: Type Conversions
- Book Chapter 02: Types and Variables
