# Lab 07: Standard Library

## Objectives
- Use string functions: `len`, `split`, `starts_with`, `ends_with`, `contains`, `substring`
- Use math functions: `sum` via loop, `array_sort` for median
- Use JSON functions: `json_encode`, `json_decode`

## Theory

PantherLang has 54+ built-in stdlib functions available without imports. The key groups are:

- **String**: `len`, `upper`, `lower`, `trim`, `contains`, `starts_with`, `ends_with`, `replace`, `split`, `join`, `substring`
- **Math**: `abs`, `max`, `min`, `pow`, `sqrt`, `floor`, `ceil`, `round`, `random`, `randint`
- **JSON**: `json_encode`, `json_decode`
- **Type Conversion**: `int`, `float`, `string`

Important argument orders:
- `join(sep, items)` — separator is first argument
- `split(text, delimiter)` — text first, delimiter second
- `substring(text, start, end)` — end is exclusive

## Exercises

### Exercise 1: String Analysis
**Task**: Given the text `"PantherLang is a modern programming language"`, count the words, check if it starts with `"Panther"`, ends with `"language"`, contains `"modern"`, and extract the first 10 characters.
**Hint**: `split(text, " ")` returns an array of words. Use `len()`, `starts_with()`, `ends_with()`, `contains()`, and `substring()`.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/07-lab.pan`

### Exercise 2: Compute Statistics
**Task**: Given the array `[85, 90, 78, 92, 88]`, compute the sum (via loop), mean, and median.
**Hint**: Use `for i in 0..4` to iterate. `array_sort()` returns a new sorted array. For 5 elements, the median is at index 2.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/07-lab.pan`

### Exercise 3: JSON Encode / Decode
**Task**: Create a user profile object `{name: "Alice", age: 30, city: "New York"}`, encode it to JSON, decode it back, and print each field.
**Hint**: `json_encode(obj)` returns a string. `json_decode(str)` returns an object. Access decoded fields with bracket notation.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/07-lab.pan`

## Summary
You used PantherLang's string, math, and JSON stdlib functions. You split text, computed statistics with loops and sorting, and serialized/deserialized JSON.

## Further Reading
- Book Chapter 07: Standard Library
- docs/STANDARD_LIBRARY.md
