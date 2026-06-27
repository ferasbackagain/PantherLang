# PantherLang Phase 6.17 — Standard Library Foundation

Adds the first deterministic Standard Library foundation.

Supported builtins:

```panther
print std.text.upper("panther")
print std.text.lower("PANTHER")
print std.math.add(10, 5)
print std.math.mul(3, 7)
print std.io.echo("hello")
```

Scope:
- standard library manifest
- builtin function registry
- compile-time stdlib evaluation
- stdlib IR metadata
- backend emission
- practical demo
- negative tests

Engineering rule: No Feature Without Proof.
