# Engineering Report — R3 Batch 4 v4

## Diagnosis
The current user regression output shows that the previous script was not executed because of a path mismatch. The remaining test collection failures are dominated by one root cause: `debug_adapter.variables` imports `ReferenceEntry` from `debug_adapter.variable_references`, but the current implementation only exposes `VariableReferenceEntry`.

## Fix strategy
This patch restores the legacy public contract while preserving the newer implementation style.

## Key changes
- Adds `ReferenceEntry = VariableReferenceEntry` compatibility alias.
- Rebuilds `VariableStore` as a dual API store:
  - legacy global `set/get/variables`
  - newer scoped `create_scope/set_variable/get_variable/snapshot/children`
- Adds `VariablesCore` facade.
- Adds `Launcher` alias for `PantherProgramLauncher`.
- Repairs public exports in `debug_adapter.__init__` and `debug_adapter.variables`.
- Adds DAP framing compatibility for older StringIO/BytesIO tests.
- Adds safe arithmetic support to `EvaluateEngine` for debug/watch expression tests.

## Local targeted proof
On the extracted project snapshot, the targeted Debug Adapter compatibility suite produced:

```text
29 passed
```

Full regression was not allowed to finish in the sandbox time window; run it locally on Kali and send the output.
