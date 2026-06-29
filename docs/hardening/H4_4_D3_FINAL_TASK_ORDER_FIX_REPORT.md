# H4.4 D3 Final Task Order Fix

Status: PASSED LOCALLY

## Fix
Preserved D1 compatibility by making the first extension task:
- PantherLang: Check

Preserved D3 workspace task:
- PantherLang: Check Current File

## Verification
- D1 regression passed.
- D2 regression passed.
- D3 regression passed.

## Rule
Do not rerun the original D3 bootstrap after this patch unless the bootstrap is updated.
