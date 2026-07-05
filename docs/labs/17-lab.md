# Lab 17: Advanced Data Processing

## Objectives
- Parse and analyze JSON data with `json_decode` / `json_encode`
- Process delimited text (CSV) with `split` and `join`
- Build a complete data pipeline: read, transform, write

## Theory
Data processing is a fundamental programming task. PantherLang provides:
- **JSON**: `json_encode(obj)` serializes to string, `json_decode(string)` parses to PantherLang objects
- **String splitting**: `split(text, delimiter)` splits into an array
- **String joining**: `join(separator, array)` joins array elements into a string
- **Sorting**: `array_sort(array)` returns a new sorted array
- **Reversing**: `array_reverse(array)` returns a new reversed array

## Exercises

### Exercise 1: Read JSON data and extract insights
**Task**: Parse a JSON string containing product data (name, price, stock). Print each product's details and total count.
**Hint**: Use `json_decode()` then iterate with `while` and numeric index.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/17-lab.pan`

### Exercise 2: Process CSV-like data
**Task**: Parse a CSV string with `split()` by newline, then `split()` each row by comma. Print formatted records using `join()`.
**Hint**: Skip the header row (index 0) when processing data.
**Verify**: The output shows each CSV row formatted with `|` separators.

### Exercise 3: Build a data pipeline
**Task**: Take raw comma-separated data, split it, sort the items alphabetically, reverse them, then join with a newline for output.
**Hint**: Chain `split` → `array_sort` → `array_reverse` → `join`.
**Verify**: The final output shows items in reverse-alphabetical order, one per line.

## Summary
You built a multi-stage data pipeline using PantherLang's JSON parsing, string manipulation, and array operations.

## Further Reading
- `compiler/stdlib/functions.py`: `_split`, `_join`, `_array_sort`, `_array_reverse`, `_json_decode`
- `examples/json_parser/main.pan`
