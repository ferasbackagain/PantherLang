# PantherLang Phase 6.13 — Loops Engine

Adds deterministic `for` loop support.

Supported syntax:

```panther
for i in 1..3 {
    print "Loop iteration"
    print i
}
```

Scope:
- range loop parsing
- loop variable binding
- loop IR
- backend emission
- practical demo
- negative tests

Engineering rule: No Feature Without Proof.
