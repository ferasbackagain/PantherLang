# PantherLang Phase 6.15 — Objects & Structs Engine

Adds deterministic struct support.

Supported syntax:

```panther
struct User {
    name
    role
}
```

Scope:
- struct declaration parsing
- field parsing
- duplicate struct validation
- struct IR
- backend metadata emission
- practical demo
- negative tests

Engineering rule: No Feature Without Proof.
