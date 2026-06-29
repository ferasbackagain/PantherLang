# PantherLang H4.3 — D8 Watch Expressions

Status: PASSED LOCALLY

## Scope
D8 adds the professional Debug Adapter watch expression model.

## Added / Updated
- Added: debug_adapter/watch_expressions.py
- Updated: debug_adapter/variables.py
- Added: tests/test_h4_3_d8_watch_expressions.py

## Implemented
- WatchExpression
- WatchExpressionStore
- WatchExpressionManager
- build_watch_manager_for_thread_store

## Capabilities
- add watch expression
- evaluate one
- evaluate all
- enable
- disable
- update expression
- remove
- clear
- snapshot

## Verification
- Static Python compilation passed.
- D8 targeted regression passed.
- D7 regression re-run passed.
- D6 regression re-run passed.
- D5 regression re-run passed.
- D4 regression re-run passed.
- D3 regression re-run passed.
- D2 regression re-run passed.
- D1 regression re-run passed.
- H4.2 F8 E2E regression re-run when present.

## Backup
.panther/backups/H4_3_d8_watch_expressions_20260628_114934

## Next
H4.3 D9 Full Regression.
