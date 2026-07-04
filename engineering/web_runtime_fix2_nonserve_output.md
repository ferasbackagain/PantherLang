# Web Runtime Fix 2 — Non-Serve Output Compatibility

## Problem
After enabling real `web {}` / `api {}` route registration for `--serve`, `execute_source()` produced empty output for Web/API examples in non-serve mode. Existing example tests expect visible Web/API placeholder output when examples are run without `--serve`.

## Fix
`execute_source()` now detects `WebBlockNode` and `ApiBlockNode`. If such blocks execute successfully but emit no output, it returns professional non-serve placeholder output that preserves CLI/example compatibility while `serve_source()` remains responsible for real HTTP serving.

## Verification
- Targeted tests for non-serve Web/API block output.
- Existing `tests/test_examples.py` placeholder expectations.
- Full regression.
