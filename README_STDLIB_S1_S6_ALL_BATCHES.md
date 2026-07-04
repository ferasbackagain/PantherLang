# PantherLang Stdlib S1-S6 All Batches

Run from the PantherLang repository root:

```bash
unzip -o pantherlang_stdlib_s1_s6_all_batches.zip
chmod +x bootstrap_stdlib_s1_s6_all_batches.sh
./bootstrap_stdlib_s1_s6_all_batches.sh
```

This adds the S1-S6 standard library expansion as prefix-style PantherLang functions compatible with the current parser:

- S1: types + I/O foundation
- S2: filesystem
- S3: system/time/random
- S4: network/http/json/sqlite
- S5: crypto
- S6: AI safe helpers

After install:

```bash
panther run examples/stdlib_s1_s6/main.pan
```
