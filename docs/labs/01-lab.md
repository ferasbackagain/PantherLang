# Lab 01: Getting Started

## Objectives
- Write and run your first PantherLang program
- Use the `print` statement to output text and values
- Work with basic expressions and string concatenation

## Theory

PantherLang programs are structured inside a `panther main { }` block — this is the entry point. The `print` statement outputs values to the console. You can print literal strings (`"Hello"`), numbers (`42`), or expressions (`15 + 27`). Use the `+` operator to concatenate strings with other values (numbers are automatically converted in concatenation).

## Exercises

### Exercise 1: Hello, Labs!
**Task**: Write a program that prints the exact text `Hello, Labs!` to the console.

**Hint**: Use `print "Hello, Labs!"` — no parentheses needed.

**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/01-lab.pan` and confirm the output is `Hello, Labs!`.

### Exercise 2: Personal Introduction
**Task**: Print two lines — your name and your age. Use separate `print` statements.

**Hint**: You can print string literals like `print "Alice"` and numbers like `print 30`.

**Verify**: The output should show two lines: first your name, then your age.

### Exercise 3: Simple Arithmetic
**Task**: Compute `15 + 27` and print the result.

**Hint**: Write `print 15 + 27` — PantherLang evaluates the expression and prints `42`.

**Verify**: Confirm the output is `42`.

## Summary
You learned how to write a PantherLang program inside `panther main {}`, use `print` for output, and evaluate basic arithmetic expressions.

## Further Reading
- Academy Lesson 01: Hello World
- Book Chapter 01: Your First Program
