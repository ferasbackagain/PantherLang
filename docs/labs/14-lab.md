# Lab 14: Language Reference — Error Codes & Debugging

## Objectives
- Understand PantherLang error codes E003, T001, and E008
- Write code that triggers and fixes each error type
- Learn to read compiler diagnostics

## Theory
PantherLang's compiler emits error codes to help diagnose problems:
- **E003**: Duplicate function definition — two functions with the same name
- **T001**: Type mismatch — assigning a value of the wrong type to an annotated variable
- **E008**: Undefined variable — referencing a variable that was never declared

Errors are caught at compile time (parsing/semantic analysis) before the program runs.

## Exercises

### Exercise 1: Trigger E003 — duplicate function
**Task**: Write two functions with the same name and observe the E003 error. Fix by renaming or removing the duplicate.
**Hint**: `fn add(x, y) { return x + y }` defined twice causes E003.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/14-lab.pan`

### Exercise 2: Trigger T001 — type mismatch
**Task**: Write `let x: string = 42` and observe T001. Fix by using the correct type or converting: `let x: string = string(42)`.
**Hint**: Type annotations use colon syntax: `let name: type = value`.
**Verify**: The solution file shows the correct pattern and explains the error.

### Exercise 3: Fix E008 — undefined variable
**Task**: Write code that references a variable `z` before declaring it. Fix by adding `let z = ...` before the reference.
**Hint**: All variables must be declared with `let` before use.
**Verify**: The solution shows the corrected code that runs without errors.

## Summary
You learned three common PantherLang error codes and how to fix them: duplicate functions (E003), type mismatches (T001), and undefined variables (E008).

## Further Reading
- `compiler/semantic/` for semantic analysis and error detection
- `compiler/types/` for type checking rules
