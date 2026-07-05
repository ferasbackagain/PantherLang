# Lab 04: Functions

## Objectives
- Define functions with `fn` inside `panther main`
- Use parameters and return values
- Call functions recursively

## Theory

Functions are defined with `fn name(params) { }` inside the `panther main` block. Use `return` to send a value back. Functions can call themselves (recursion). Parameters are untyped — PantherLang infers types at runtime.

**Important**: Nested function definitions are not supported. Define all functions at the top level of `panther main { }`.

## Exercises

### Exercise 1: Is Even
**Task**: Write a function `is_even(n)` that returns `true` if `n` is even, `false` otherwise. Test it with the values 4 and 7.

**Hint**: A number is even if `n % 2 == 0`. Use `if/else` inside the function. Call it like `print is_even(4)`.

**Verify**: `is_even(4)` should print `true`, `is_even(7)` should print `false`.

### Exercise 2: Recursive Sum
**Task**: Write a recursive function `sum_to(n)` that returns the sum of all integers from 1 to n. Test with `sum_to(5)` and `sum_to(100)`.

**Hint**: Base case: `if n <= 1 return n`. Recursive case: `return n + sum_to(n - 1)`.

**Verify**: `sum_to(5)` should output `15`, `sum_to(100)` should output `5050`.

### Exercise 3: Celsius to Fahrenheit
**Task**: Write a function `celsius_to_fahrenheit(c)` that converts Celsius to Fahrenheit using the formula `F = C * 9/5 + 32`. Test with 0, 100, and 37.

**Hint**: PantherLang does floating-point arithmetic naturally. Use `c * 9 / 5 + 32`. Test with `print celsius_to_fahrenheit(100)`.

**Verify**: 0°C → 32°F, 100°C → 212°F, 37°C → 98.6°F.

## Summary
You learned how to define functions with parameters and return values, and how to use recursion for mathematical computations.

## Further Reading
- Academy Lesson 05: Functions
- Academy Lesson 06: Recursion
- Book Chapter 05: Functions
