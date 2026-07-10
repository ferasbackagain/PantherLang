"""Phase C5 — Data/Serialization Tests

Tests for data processing functions:
- datetime_now, datetime_format, datetime_parse
- csv_parse, csv_stringify, csv_parse_objects
- url_encode, url_decode
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from compiler.runtime import execute_source


class TestDateTime:
    def test_datetime_now_iso(self):
        """datetime_now() should return an ISO 8601 string."""
        src = 'panther main {\n    print(datetime_now());\n}\n'
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output).strip()
        assert "T" in out  # ISO 8601 contains T separator
        assert len(out) > 10

    def test_datetime_format_epoch(self):
        """datetime_format(0) should return year near 1970 epoch (timezone-dependent)."""
        src = 'panther main {\n    print(datetime_format(0, "%Y"));\n}\n'
        result = execute_source(src)
        assert result.error is None
        year = "".join(result.captured_output).strip()
        assert year in ("1969", "1970", "1971")  # timezone dependent

    def test_datetime_format_default(self):
        """datetime_format with default format should return YYYY-MM-DD HH:MM:SS."""
        src = 'panther main {\n    let d = datetime_format(1000000000);\n    print(to_string(len(d)));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "".join(result.captured_output).strip() == "19"  # "2001-09-09 01:46:40" is 19 chars

    def test_datetime_parse_iso(self):
        """datetime_parse should parse ISO dates to Unix timestamps."""
        src = 'panther main {\n    print(to_string(datetime_parse("2026-01-01")));\n}\n'
        result = execute_source(src)
        assert result.error is None
        ts = float("".join(result.captured_output).strip())
        assert ts > 1700000000  # 2026-01-01 is > 2023

    def test_datetime_parse_invalid(self):
        """datetime_parse should return 0 for invalid input."""
        src = 'panther main {\n    print(to_string(datetime_parse("not-a-date")));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "".join(result.captured_output).strip() == "0.0"


class TestCSV:
    def test_csv_parse_simple(self):
        """csv_parse should parse simple CSV."""
        src = """panther main {
    let r = csv_parse("a,b,c\\n1,2,3");
    print(r[0][0]);
    print(r[1][2]);
}"""
        result = execute_source(src)
        assert result.error is None
        out = result.captured_output
        assert out[0].strip() == "a"
        assert out[1].strip() == "3"

    def test_csv_stringify(self):
        """csv_stringify should produce CSV text."""
        src = """panther main {
    let text = csv_stringify([["x","y"],["1","2"]]);
    print(text);
}"""
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output)
        assert "x,y" in out
        assert "1,2" in out

    def test_csv_parse_objects(self):
        """csv_parse_objects should return dict rows with header keys."""
        src = """panther main {
    let r = csv_parse_objects("name,age\\nAlice,30\\nBob,25");
    print(r[0]["name"]);
    print(r[0]["age"]);
    print(r[1]["name"]);
}"""
        result = execute_source(src)
        assert result.error is None
        out = result.captured_output
        assert out[0].strip() == "Alice"
        assert out[1].strip() == "30"
        assert out[2].strip() == "Bob"


class TestURLEncoding:
    def test_url_encode(self):
        """url_encode should percent-encode special characters."""
        src = 'panther main {\n    print(url_encode("hello world"));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "".join(result.captured_output).strip() == "hello%20world"

    def test_url_decode(self):
        """url_decode should reverse percent-encoding."""
        src = 'panther main {\n    print(url_decode("hello%20world"));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "".join(result.captured_output).strip() == "hello world"

    def test_url_roundtrip(self):
        """URL encode then decode should return original."""
        src = """panther main {
    let orig = "a=1&b=2+3/4";
    let enc = url_encode(orig);
    let dec = url_decode(enc);
    print(dec);
}"""
        result = execute_source(src)
        assert result.error is None
        assert "".join(result.captured_output).strip() == "a=1&b=2+3/4"
