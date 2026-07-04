# PantherLang v1.1.5 RC1 — Comparison Runtime Stabilization

This package is the first formal release-candidate style stabilization patch.

It implements/validates:

- PDL-005: Comparison operators require compatible operand types.
- `PT002` for incompatible comparisons.
- Regression tests for `==`, `!=`, `>`, `<`, `>=`, `<=`.
- Panther Academy Lesson 06 verification program.
- Book/spec documentation for comparison semantics.

Run from repository root:

```bash
unzip -o pantherlang_v1_1_5_rc1_comparison_runtime_stabilization.zip
chmod +x bootstrap_panther_v1_1_5_rc1_comparison_runtime.sh
./bootstrap_panther_v1_1_5_rc1_comparison_runtime.sh
```

Manual check:

```bash
panther run academy/lesson06/comparison_policy.pan
```
