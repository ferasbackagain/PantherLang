# Lab 15: Comparison Semantics

## Objectives
- Use comparison operators (`==`, `!=`, `<`, `>`, `<=`, `>=`) across different types
- Perform explicit type conversion before cross-type comparison
- Understand null equality semantics

## Theory
PantherLang supports same-type comparisons natively. Cross-type comparisons require explicit conversion using `string()`, `int()`, or `float()`. The `null` value has specific equality semantics: it is only equal to `null`, not to `0`, `false`, or an empty string.

Comparison operators:
- `==` / `!=`: equality / inequality
- `<` / `>`: less than / greater than
- `<=` / `>=`: less than or equal / greater than or equal

Supported types: `int`, `float`, `string`, `bool`, `null`

## Exercises

### Exercise 1: Comparison expressions for each type
**Task**: Write comparison expressions for `int`, `float`, `string`, and `bool` types. Test `==`, `!=`, `<`, `>`, `<=`, `>=`.
**Hint**: Use `string()` to convert comparison results to strings for printing.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/15-lab.pan`

### Exercise 2: Convert and compare (int to float)
**Task**: Compare an `int` to a `float` by converting one to the other's type first using `float()` or `int()`.
**Hint**: `float(42) == 42.0` works after explicit conversion.
**Verify**: The output shows correct true/false results for converted comparisons.

### Exercise 3: Demonstrate null semantics
**Task**: Show that `null == null` is true, but `null == 0`, `null == false`, and `null == ""` are all false.
**Hint**: `null` only equals `null` — it is not equal to `0`, `false`, or empty strings.
**Verify**: The null comparison results print correctly.

## Summary
You learned PantherLang's comparison semantics: same-type comparisons, explicit cross-type conversion, and null behavior.

## Further Reading
- `compiler/types/type_checker.py` for type compatibility rules
- `examples/conformance/06_expressions_operators.pan`
