# PDL-005 — Comparison Semantics

PantherLang comparison operators require compatible operand types.

Supported compatible comparisons:

- `int` with `int`
- `float` with `float`
- `int` with `float`
- `string` with `string`
- `bool` with `bool`
- arrays with arrays, when supported by the runtime
- objects with objects, when supported by the runtime

Unsupported mixed-type comparisons must raise `PT002`.

Examples:

```panther
print 100 == "100";   // PT002
print true == 1;       // PT002
print "true" == true; // PT002
```

Use explicit conversion:

```panther
print to_int("100") == 100;
print to_string(100) == "100";
```
