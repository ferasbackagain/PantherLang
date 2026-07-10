"""Phase C0 — Release Correctness Tests

Tests for cross-platform source file handling:
- UTF-8 BOM
- CRLF line endings
- Unicode source
- Empty source
- Whitespace-only source
"""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from compiler.lexer import lex_source, LexerError
from compiler.runtime import execute_source


class TestBOMHandling:
    def test_bom_stripped_during_lexing(self):
        """BOM character should be silently stripped during lexing."""
        tokens = lex_source("\ufeffpanther main {\n}\n")
        # Should produce the same tokens as without BOM
        assert len(tokens) > 0
        assert tokens[0].lexeme == "panther"

    def test_bom_and_normal_produce_same_tokens(self):
        """BOM source and normal source should produce identical token streams."""
        bom_src = "\ufeffpanther main {\n    print(42);\n}\n"
        normal_src = "panther main {\n    print(42);\n}\n"
        bom_tokens = lex_source(bom_src)
        normal_tokens = lex_source(normal_src)
        assert len(bom_tokens) == len(normal_tokens)
        for bt, nt in zip(bom_tokens, normal_tokens):
            assert bt.kind == nt.kind

    def test_bom_runtime_execution(self):
        """PantherLang program with BOM should execute correctly."""
        src = "\ufeffpanther main {\n    print(\"BOM_OK\");\n}\n"
        result = execute_source(src)
        assert result.error is None
        assert "BOM_OK" in "".join(result.captured_output)

    def test_bom_from_file(self):
        """A .pan file on disk with BOM should load and execute."""
        with tempfile.NamedTemporaryFile(
            mode="wb", suffix=".pan", delete=False
        ) as f:
            f.write("\ufeffpanther main {\n    print(\"BOM_FILE_OK\");\n}\n".encode("utf-8"))
            tmp = Path(f.name)
        try:
            text = tmp.read_text(encoding="utf-8")
            assert text[0] == "\ufeff"
            result = execute_source(text)
            assert result.error is None
            assert "BOM_FILE_OK" in "".join(result.captured_output)
        finally:
            tmp.unlink()


class TestCRLFHandling:
    def test_crlf_lexing(self):
        """CRLF line endings should be handled correctly."""
        src = "panther main {\r\n    print(1);\r\n}\r\n"
        tokens = lex_source(src)
        assert len(tokens) > 0
        assert tokens[0].lexeme == "panther"

    def test_crlf_runtime(self):
        """CRLF source should execute correctly."""
        src = "panther main {\r\n    print(\"CRLF_OK\");\r\n}\r\n"
        result = execute_source(src)
        assert result.error is None
        assert "CRLF_OK" in "".join(result.captured_output)


class TestUnicodeSource:
    def test_unicode_identifiers(self):
        """Unicode identifiers should lex and execute."""
        src = 'panther main {\n    let 日本語 = "unicode";\n    print(日本語);\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "unicode" in "".join(result.captured_output)

    def test_unicode_strings(self):
        """Unicode content in strings should work."""
        src = 'panther main {\n    print("¡Hola! 你好 😊");\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "Hola" in "".join(result.captured_output)

    def test_mixed_ascii_unicode(self):
        """Mixed ASCII and Unicode identifiers."""
        src = 'panther main {\n    let café_laȚe = 42;\n    print(to_string(café_laȚe));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "42" in "".join(result.captured_output)


class TestEmptySourceHandling:
    def test_empty_source_lexes(self):
        """Empty source should lex to just EOF token."""
        tokens = lex_source("")
        assert len(tokens) == 1
        assert tokens[0].lexeme == ""

    def test_empty_body_program(self):
        """A program with empty main body should parse and run."""
        src = "panther main {\n}\n"
        result = execute_source(src)
        assert result.error is None

    def test_whitespace_only(self):
        """Whitespace-only source should not crash."""
        src = "   \n   \n"
        result = execute_source(src)
        assert result.error is None

    def test_newlines_only(self):
        """Newlines-only source should not crash."""
        src = "\n\n\n\n"
        result = execute_source(src)
        assert result.error is None


class TestNullByteHandling:
    def test_null_byte_raises_error(self):
        """Null bytes should raise a lexer error (corrupted source detection)."""
        with pytest.raises(LexerError, match="Unexpected character"):
            lex_source("panther mai\x00n {\n}\n")
