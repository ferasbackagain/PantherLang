# Lab 16: Contributing & Ecosystem

## Objectives
- Set up a PantherLang development environment
- Run specific test files to verify changes
- Create a new project from a template

## Theory
PantherLang uses a standard Python development workflow. The project is structured with a compiler pipeline (lexer, parser, AST, semantic analysis, type checking, runtime) and extensive tests (1000+). Contributions follow a typical PR workflow: fork, branch, commit, push, and create a pull request.

## Exercises

### Exercise 1: Set up development environment
**Task**: Install PantherLang in editable mode with dev dependencies: `pip install -e ".[dev]"`.
**Hint**: Run from the project root directory. Use `pip install -e ".[dev]"` (the quotes are important in zsh).
**Verify**: Run `python -m pytest --collect-only` to confirm tests are discoverable.

### Exercise 2: Run a specific test file
**Task**: Run `python -m pytest tests/security/test_web_security.py -v` to execute web security tests.
**Hint**: Use the `-v` flag for verbose output showing each test name and result.
**Verify**: All tests should pass (0 failed).

### Exercise 3: Create a project from a template
**Task**: Create a new console project using the template in `project_templates/console/`.
**Hint**: Copy the template files to a new directory and run `panther run main.pan`.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/16-lab.pan`

## Summary
You learned the PantherLang development workflow: environment setup, test execution, and project scaffolding from templates.

## Further Reading
- `CONTRIBUTING.md` in the project root
- `project_templates/` for available templates
- `tests/` for the test suite structure
