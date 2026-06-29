Atomic sequence:
1. Verify rebuilt adapter.
2. Backup legacy debug_adapter.
3. Rename debug_adapter -> debug_adapter_legacy.
4. Promote debug_adapter_rebuilt -> debug_adapter.
5. Execute H4 regression.
6. Roll back immediately on failure.
