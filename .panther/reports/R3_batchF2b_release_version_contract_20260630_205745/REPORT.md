# R3 Batch F2b — Release Version Contract Fix

Fixed stale hardcoded VS Code extension version assertion.

Result:
- package.json may remain at 1.1.3
- test validates semver format instead of forcing 1.1.2

Next:
- python3 -m pytest -q
