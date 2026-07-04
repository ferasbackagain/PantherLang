# PantherLang Local Release Checklist

## Git Clean Status

- [ ] Branch is `main`
- [ ] No staged changes pending
- [ ] `.gitignore` exists and covers `__pycache__/`, `*.pyc`, `*.zip`, `*.tar.gz`, `*.vsix`, `.panther/`, `.panther_backups/`, `.phase_backups/`
- [ ] No `.pyc` files tracked in git
- [ ] No archive files (`.zip`, `.tar.gz`, `.vsix`) tracked in git
- [ ] `README.md`, `LICENSE`, `CHANGELOG.md` present

## Regression Status

- [ ] `python -m pytest -q` passes (0 failed, 0 errors)
- [ ] `python -m pytest tests/test_examples.py -v` passes (14/14)
- [ ] `python -m pytest tests/test_book_content.py -v` passes
- [ ] `python -m pytest tests/test_docs_presence.py -v` passes

## Examples Status

- [ ] `bash scripts/run_examples.sh` runs all examples without error
- [ ] `panther run examples/console_hello/main.pan` — Hello from PantherLang
- [ ] `panther run examples/calculator/calc.pan` — factorial(7) = 5040
- [ ] `panther run examples/json_parser/main.pan` — JSON encode/decode
- [ ] `panther run examples/sqlite_crud/main.pan` — SQLite CRUD
- [ ] `panther run examples/file_manager/main.pan` — filesystem operations
- [ ] `panther run examples/http_client/main.pan` — HTTP client
- [ ] `panther run examples/config_loader/main.pan` — config loading
- [ ] `panther run examples/security_audit_demo/main.pan` — security audit
- [ ] `panther run examples/hello_api/main.pan` — API template
- [ ] `panther run examples/hello_web/main.pan` — Web template
- [ ] `panther run examples/hello_ai/main.pan` — AI template

## CLI Status

- [ ] `panther version` — shows version 1.0.0
- [ ] `panther doctor` — all 11 components OK
- [ ] `panther --help` — professional output
- [ ] `panther new console test_console` — creates project
- [ ] `panther run test_console/src/main.panther` — runs created project
- [ ] `panther check examples/console_hello/main.pan` — validates syntax
- [ ] `panther build examples/console_hello/main.pan` — builds artifact
- [ ] `panther fmt examples/console_hello/main.pan` — format check

## VS Code Local Install

- [ ] `vscode-extension/package.json` exists with valid metadata
- [ ] `vscode-extension/README.md` exists
- [ ] `vscode-extension/CHANGELOG.md` exists
- [ ] `npm install` succeeds in `vscode-extension/`
- [ ] `vsce package` creates `.vsix` file
- [ ] `code --install-extension *.vsix` installs without error
- [ ] Syntax highlighting works on `.panther` file
- [ ] File icon shows for `.panther`/`.pan` files
- [ ] Snippets available (`pn-main`, `pn-fn`, `pn-let`, etc.)
- [ ] Run command works (Ctrl+Shift+P → Panther: Run File)

## Linux Test Status

- [ ] `python3 --version >= 3.10`
- [ ] `pip install -e ".[dev]"` succeeds
- [ ] `panther doctor` — all OK
- [ ] Full regression passes

## Windows Test Plan

- [ ] Python 3.10+ installed
- [ ] `pip install pantherlang` or `pip install -e ".[dev]"`
- [ ] `panther doctor` reports all OK
- [ ] `panther run` on example files
- [ ] `scripts/run_examples.bat` or `scripts/run_examples.ps1`

## macOS Test Plan

- [ ] Python 3.10+ available
- [ ] `pip3 install pantherlang` or `pip install -e ".[dev]"`
- [ ] `panther doctor` reports all OK
- [ ] `bash scripts/run_examples.sh`

## Documentation Status

- [ ] `docs/book/THE_PANTHER_PROGRAMMING_LANGUAGE.md` — complete book
- [ ] `docs/book/chapters/` — 14 chapter files
- [ ] `docs/book/examples-index.md` — all 11 verified examples
- [ ] `docs/book/language-feature-map.md` — feature mapping
- [ ] `docs/KALI_TEST_COMMANDS.md` — Kali test commands
- [ ] `docs/WINDOWS_TEST_COMMANDS.md` — Windows test commands
- [ ] `docs/MACOS_TEST_COMMANDS.md` — macOS test commands
- [ ] `docs/START_HERE_FOR_DEVELOPERS.md` — developer guide
- [ ] `docs/VSCODE_LOCAL_RELEASE_TEST.md` — VS Code test guide
- [ ] `docs/PANTHERLANG_SOURCE_FILES_INDEX.md` — all source files
- [ ] `engineering/master_branch_readiness_report.md` — branch state

## PyPI Readiness

- [ ] `pyproject.toml` has correct metadata
- [ ] `python -m build` succeeds
- [ ] `twine check dist/*` passes

## GitHub Readiness

- [ ] `README.md` has install/quickstart/docs links
- [ ] `LICENSE` file present
- [ ] `CHANGELOG.md` documents versions
- [ ] `AGENTS.md` present with AI agent instructions

## Marketplace Readiness

- [ ] Extension packaged as `.vsix`
- [ ] `publisher` set in `package.json`
- [ ] Extension name and description accurate
- [ ] Icon file included

## Blockers

- [ ] `--serve` flag does not start HTTP server from Panther source (prints mock output)
- [ ] `panther new` creates `.panther` files in `src/main.panther` not `.pan`
- [ ] Enums/traits parsed but not runtime-executable
- [ ] Package manager CLI not integrated into `panther` command

## Next Steps

1. Commit `.gitignore` and documentation changes
2. Run full regression one final time
3. Build and verify VS Code extension locally
4. Optionally publish to PyPI: `twine upload dist/*`
5. Optionally publish to VS Code Marketplace
6. Tag release: `git tag v1.0.0 && git push origin v1.0.0`
