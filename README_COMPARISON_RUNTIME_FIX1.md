# Comparison Runtime Fix 1

This batch unifies PantherLang comparison operator policy.

## Goal

Mixed-type comparisons such as `100 == "100"` should not silently return `false`. They should raise a Panther type error (`PT002`) so PantherLang remains consistent with the explicit conversion policy.

## Run

```bash
unzip -o pantherlang_comparison_runtime_fix1.zip
chmod +x bootstrap_comparison_runtime_fix1.sh
./bootstrap_comparison_runtime_fix1.sh
```

## Adds

- PDL-005 documentation
- Panther Academy Lesson 06 documentation
- Lesson 06 example
- Regression tests
