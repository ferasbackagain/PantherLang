from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

VERIFIED_EXAMPLES = [
    "console_hello",
    "calculator",
    "hello_api",
    "hello_web",
    "hello_ai",
    "security_audit_demo",
    "file_manager",
    "sqlite_crud",
    "http_client",
    "json_parser",
    "config_loader",
]

BOOK_FILES = [
    ROOT / "docs/book/THE_PANTHER_PROGRAMMING_LANGUAGE.md",
    ROOT / "docs/book/examples-index.md",
    ROOT / "docs/book/language-feature-map.md",
]

CHAPTER_DIR = ROOT / "docs/book/chapters"


def _iter_book_files():
    yield from BOOK_FILES
    yield from sorted(CHAPTER_DIR.glob("*.md"))


def test_all_book_files_exist():
    for f in _iter_book_files():
        assert f.exists(), f"Missing book file: {f}"


def test_book_only_references_verified_examples():
    for filepath in _iter_book_files():
        content = filepath.read_text(encoding="utf-8")
        for line in content.splitlines():
            for ex in VERIFIED_EXAMPLES:
                if f"examples/{ex}/" in line or f"`{ex}`" in line:
                    break


def test_examples_index_lists_all_verified():
    content = (ROOT / "docs/book/examples-index.md").read_text(encoding="utf-8")
    for ex in VERIFIED_EXAMPLES:
        assert ex in content, f"examples-index.md missing verified example: {ex}"


def test_features_map_uses_verified_examples():
    content = (ROOT / "docs/book/language-feature-map.md").read_text(encoding="utf-8")
    for ex in VERIFIED_EXAMPLES:
        assert ex in content, f"language-feature-map.md missing reference to {ex}"


def test_no_phantom_example_references():
    all_book_text = ""
    for filepath in _iter_book_files():
        all_book_text += filepath.read_text(encoding="utf-8")

    for filepath in sorted(Path(ROOT / "examples").iterdir()):
        if filepath.is_dir():
            name = filepath.name
            pattern = f"examples/{name}/"
            if pattern in all_book_text:
                assert name in VERIFIED_EXAMPLES, (
                    f"Book references example '{name}' (via '{pattern}') which is not in the "
                    f"verified list. Either add it to VERIFIED_EXAMPLES or remove from book."
                )
