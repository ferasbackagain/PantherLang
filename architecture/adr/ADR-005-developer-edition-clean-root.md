# ADR-005 — Developer Edition Clean Root

## Status
Accepted

## Decision
From v0.5 onward, PantherLang releases are full clean repository editions, not small patch ZIP files.

## Reason
Patch files caused confusion between root examples and language examples.

## Consequence
All executable examples live in:

```text
language/examples/
```

Root `examples/` is reserved for future cross-product examples only.
