# PantherLang v1.1.5 RC1b — Equality Comparison PT002 Patch

Fixes mixed-type equality/inequality comparisons so `==` and `!=` follow PDL-005 and raise `PT002` instead of returning Python-style `true/false`.

Run from repository root:

```bash
unzip -o pantherlang_v1_1_5_rc1b_comparison_equality_patch.zip
chmod +x bootstrap_panther_v1_1_5_rc1b_comparison_equality_patch.sh
./bootstrap_panther_v1_1_5_rc1b_comparison_equality_patch.sh
```
