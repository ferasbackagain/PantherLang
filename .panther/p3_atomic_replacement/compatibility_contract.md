Goal:
- Replace debug_adapter with debug_adapter_rebuilt atomically.
- Preserve public API.
- No runtime mutation during planning.
- Rollback must remain possible.
