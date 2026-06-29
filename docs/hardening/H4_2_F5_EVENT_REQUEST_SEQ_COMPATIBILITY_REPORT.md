# PantherLang H4.2 — F5 Event request_seq Compatibility Patch

Status: PASSED LOCALLY

## Problem
Part2B v2 regression expects DAP events returned from request dispatch to contain request_seq.

## Fix
Updated response_merge.py event normalization to preserve event routing while attaching:
- request_seq
- sourceCommand

## Verification
- Event request_seq compatibility passed.
- Part2B v2 DAP routing regression passed.
- F5 event dispatcher compatibility passed.
- F4 response merge regression passed.
- F5 event merge regression passed.

## Backup
.panther/backups/H4_2_f5_event_request_seq_20260628_103247

## Next
Run F6 Execution Merge.
