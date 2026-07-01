# R3 Batch F1 — Developer Tooling Final Fixes

Applied:
- Restored repo-local ./panther launcher without recursion.
- Added panther version/help wrapper behavior.
- Installed global ~/.local/bin/panther wrapper.
- Added VS Code PantherLang file icon theme for .pan and .panther.
- Ensured VS Code package metadata/contributions are stable.

Validation:
- panther version
- panther check examples/hello.pan
- VS Code icon theme contract check

Next:
- Run full regression:
  python3 -m pytest -q
- Rebuild VSIX only after regression is clean.
