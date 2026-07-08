# PantherLang Public Repository Cleanup Report

## Scope
Conservative public-repository cleanup of the uploaded GitHub clone.

## Preserved
Active compiler, runtime, CLI, tests, docs, Academy, examples, language specifications,
project templates, package manager, debug adapter, `debug_adapter_rebuilt`, VS Code
extension, website, installers, and release-engineering source.

## Removed
- `.panther/`, `.panther_backups/`, `.panther_cache/`
- root historical `bootstrap_*.sh`
- root archived `.zip` engineering bundles
- batch manifest files
- historical fix-specific README files
- internal master prompts and launch/audit notes
- local SQLite databases
- local diary/task data
- temporary sample/test roots
- legacy duplicate debug tree
- historical restoration-script directories
- old `releases/` artifact directory

## Verification note
`debug_adapter_rebuilt` was retained because test collection proved it is still an active
dependency of current tests/import bridges.

A full regression was attempted in the execution environment. It progressed substantially
but exceeded the available execution timeout and showed failures early in the run.
Therefore this package does not claim a fresh full-regression PASS.

Before public push, run the complete regression on Kali and review every failure.
