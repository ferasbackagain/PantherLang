# Lab 13: Cross-Platform Development

## Objectives
- Write PantherLang code that works on Linux, macOS, and Windows
- Use `sanitize_path` for safe cross-platform file access
- Build a script runner that detects the operating system

## Theory
Cross-platform development means writing code that behaves consistently across operating systems. PantherLang provides `system_os()` to detect the platform and `sanitize_path(base, path)` to safely resolve file paths regardless of OS path conventions. The `join()` function is useful for building paths with forward slashes that work universally.

Key differences:
- **Linux**: `/tmp`, `/home/user`, case-sensitive paths
- **macOS (Darwin)**: `/tmp`, `/Users/user`, case-insensitive by default
- **Windows**: `C:\Users\user`, `C:\Temp`, backslash paths, case-insensitive

## Exercises

### Exercise 1: Cross-platform file path handler
**Task**: Write a `normalize_path` function that takes an array of path segments and joins them with `/` to create a portable path string.
**Hint**: Use `join("/", parts)` — the separator is the first argument.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/13-lab.pan`

### Exercise 2: Safe file access with sanitize_path
**Task**: Use `sanitize_path(base, user_path)` to safely resolve a user-supplied filename within a sandbox directory. Verify that path traversal (`../etc/passwd`) is blocked.
**Hint**: `sanitize_path` raises an error if the resolved path escapes the base directory.
**Verify**: Check the output shows the safe path and mentions traversal blocking.

### Exercise 3: Cross-platform script runner
**Task**: Detect the current operating system with `system_os()` and print platform-specific setup instructions.
**Hint**: `system_os()` returns `"Linux"`, `"Darwin"` (macOS), or `"Windows"`.
**Verify**: The output should show the detected OS and hostname.

## Summary
You learned to write cross-platform PantherLang code using `system_os()`, `sanitize_path()`, and portable path building with `join()`.

## Further Reading
- `compiler/stdlib/functions.py`: `_sanitize_path`, `_system_os`, `_system_hostname`
- `docs/specification/` for language specification
