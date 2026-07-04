# Web Runtime Fix 1 — AST Export Repair

This patch restores `compiler/ast/__init__.py` exports required by the runtime and tests.

It fixes:

```text
ImportError: cannot import name 'BreakStatement' from 'compiler.ast'
```

Run from repository root:

```bash
unzip -o pantherlang_web_runtime_fix1_ast_export_fix.zip
chmod +x bootstrap_web_runtime_fix1_ast_export_fix.sh
./bootstrap_web_runtime_fix1_ast_export_fix.sh
```
