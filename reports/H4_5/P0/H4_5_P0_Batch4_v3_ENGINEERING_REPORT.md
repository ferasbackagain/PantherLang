# H4.5 P0 Batch 4 v3 Engineering Report

## Status

FAILED

## Mode

Selective Runtime Restore + Read-Only Regression.

## Why v3 exists

Batch 4 v2 restored the entire `debug_adapter` directory from an H4.2-era backup, which removed later H4.3/H4.4 modules. Batch 4 v3 fixes that by restoring only missing H4.3/H4.4 modules from the pre-v2 safety backup without overwriting existing runtime files.

## Source Backup

`.panther/backups/H4_5_P0_Batch4_v2_20260628_174235/debug_adapter`

## Copied Required Modules

```json
[
  "variables_core.py",
  "variable_references.py",
  "variable_store.py",
  "stack_frames.py",
  "threads.py",
  "scopes.py",
  "evaluate.py",
  "execution_dispatcher.py"
]
```

## Already Present Required Modules

```json
[]
```

## Missing From Source

```json
[]
```

## Extra Missing Files Recovered

```json
[
  "variables.py",
  "execution_merge.py",
  "watch_expressions.py"
]
```

## Compile Return Code

`0`

## Pytest Return Code

`1`

## Errors

```json
[
  "H4 regression failed"
]
```

## Next

If PASSED: H4.5 P0 Batch 5 - Final P0 Report + Status Gate.
If FAILED: inspect `.panther/h4_5_p0/runtime_validation_batch4_v3.json`.
