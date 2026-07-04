# Panther Academy Lessons 01-05 Fix Report

## Decision
PantherLang keeps strict typing: no implicit conversion.

## Added
- Panther Runtime Error PR001 for division/modulo by zero.
- Panther Type Error PT001 for invalid mixed-type binary operations.
- Explicit conversion helpers: `to_string`, `to_int`, `to_float`, `to_number`, `to_bool`, `type_of`.
- IO foundation helpers: `input`, `readline`, `println`.

## Example
`examples/academy/lesson05_conversions.pan`

## Rule
Use explicit conversion when mixing values:

```panther
print println("Age", age);
print to_string(age);
```
