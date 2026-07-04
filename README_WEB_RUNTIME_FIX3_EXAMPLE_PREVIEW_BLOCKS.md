# Web Runtime Fix 3 — Example Preview Blocks

Fixes the semantic conflict between:

- `web {}` / `api {}` blocks registering routes silently in `execute_source()` tests.
- Web/API example files needing visible non-serve preview output.

The fix keeps generic web/api blocks silent, and adds explicit `panther main { ... }` preview blocks to the real example files.

Run:

```bash
unzip -o pantherlang_web_runtime_fix3_example_preview_blocks.zip
chmod +x bootstrap_web_runtime_fix3_example_preview_blocks.sh
./bootstrap_web_runtime_fix3_example_preview_blocks.sh
```
