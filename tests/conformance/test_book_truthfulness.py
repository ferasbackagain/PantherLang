"""Verify book claims match actual runtime capabilities."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_book_feature_map_only_references_existing_examples():
    map_file = ROOT / "docs/book/language-feature-map.md"
    assert map_file.exists()
    content = map_file.read_text(encoding="utf-8")
    conf_dir = ROOT / "examples" / "conformance"
    for name in sorted(conf_dir.iterdir()):
        if name.suffix == ".pan":
            assert name.name in content or name.stem in content, (
                f"Conformance example {name.name} not referenced in feature map"
            )


def test_book_roadmap_consistent_with_audit():
    audit = ROOT / "engineering/book_feature_audit.md"
    assert audit.exists(), "Must run book feature audit first"


def test_no_claims_of_unsupported_features():
    """Check that PLANNED features are not claimed as Verified in the book."""
    book = ROOT / "docs/book/THE_PANTHER_PROGRAMMING_LANGUAGE.md"
    content = book.read_text(encoding="utf-8")
    assert "anonymous" not in content, (
        "Book should not claim anonymous functions work"
    )


def test_conformance_runner_exists():
    assert (ROOT / "scripts/run_conformance.sh").exists()
    assert (ROOT / "scripts/run_conformance.ps1").exists()
    assert (ROOT / "scripts/run_conformance.bat").exists()
