from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_DOCS = [
    "README.md",
    "CHANGELOG.md",
    "AGENTS.md",
    "LICENSE",
    "docs/ARCHITECTURE.md",
    "docs/CLI_GUIDE.md",
    "docs/SECURITY_GUIDE.md",
    "docs/DEVELOPER_GUIDE.md",
    "docs/LANGUAGE_REFERENCE.md",
    "docs/PANTHERLANG_PRACTICAL_LANGUAGE_GUIDE.md",
    "docs/book/THE_PANTHER_PROGRAMMING_LANGUAGE_OUTLINE.md",
    "docs/book/THE_PANTHER_PROGRAMMING_LANGUAGE.md",
    "docs/book/examples-index.md",
    "docs/book/language-feature-map.md",
    "docs/book/chapters/01-getting-started.md",
    "docs/book/chapters/02-variables-and-types.md",
    "docs/book/chapters/03-expressions-and-operators.md",
    "docs/book/chapters/04-control-flow.md",
    "docs/book/chapters/05-functions.md",
    "docs/book/chapters/06-data-structures.md",
    "docs/book/chapters/07-standard-library.md",
    "docs/book/chapters/08-security.md",
    "docs/book/chapters/09-web-platform.md",
    "docs/book/chapters/10-database-platform.md",
    "docs/book/chapters/11-ai-platform.md",
    "docs/book/chapters/12-cli-and-tooling.md",
    "docs/book/chapters/13-cross-platform.md",
    "docs/book/chapters/14-language-reference.md",
    "engineering/language_first_audit.md",
    "examples/README.md",
    "examples/console_hello/README.md",
    "examples/calculator/README.md",
    "examples/hello_api/README.md",
    "examples/hello_web/README.md",
    "examples/hello_ai/README.md",
    "examples/security_audit_demo/README.md",
    "scripts/run_examples.sh",
    "scripts/run_examples.ps1",
    "scripts/run_examples.bat",
    "pyproject.toml",
    "MANIFEST.in",
]


def test_required_docs_exist():
    missing = []
    for doc in REQUIRED_DOCS:
        path = ROOT / doc
        if not path.exists():
            missing.append(doc)
    assert not missing, f"Missing documentation: {missing}"


def test_readme_contains_quick_install():
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    assert "pip install" in readme


def test_changelog_contains_version():
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    assert "1.0.0" in changelog


def test_examples_readme_lists_examples():
    readme = (ROOT / "examples" / "README.md").read_text(encoding="utf-8")
    for name in ["console_hello", "calculator", "hello_api", "hello_web", "hello_ai", "security_audit_demo"]:
        assert name in readme


def test_agents_md_exists():
    agents = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
    assert "pip install pantherlang" in agents
    assert "panther" in agents


def test_pyproject_exists():
    content = (ROOT / "pyproject.toml").read_text(encoding="utf-8")
    assert "pantherlang" in content
    assert "panther" in content
