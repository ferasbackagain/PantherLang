"""Phase C10 — Observability Tests

Tests for logging functions (log_debug, log_info, log_warn, log_error, log_set_level).
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from compiler.runtime import execute_source


class TestLogging:
    def test_log_info(self):
        src = """panther main {
    log_set_level("info");
    print(log_info("hello"));
}"""
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output)
        assert "[INFO]" in out
        assert "hello" in out

    def test_log_warn(self):
        src = """panther main {
    log_set_level("info");
    print(log_warn("careful"));
}"""
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output)
        assert "[WARN]" in out
        assert "careful" in out

    def test_log_error(self):
        src = """panther main {
    log_set_level("info");
    print(log_error("fail"));
}"""
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output)
        assert "[ERROR]" in out
        assert "fail" in out

    def test_log_debug_filtered(self):
        src = """panther main {
    print(log_debug("secret"));
}"""
        result = execute_source(src)
        assert result.error is None
        assert "".join(result.captured_output).strip() == ""

    def test_log_debug_enabled(self):
        src = """panther main {
    log_set_level("debug");
    print(log_debug("visible"));
}"""
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output)
        assert "[DEBUG]" in out
        assert "visible" in out

    def test_log_set_level_invalid(self):
        src = """panther main {
    print(to_string(log_set_level("invalid")));
}"""
        result = execute_source(src)
        assert result.error is None
        assert "".join(result.captured_output).strip() == "false"

    def test_log_timestamp_format(self):
        src = """panther main {
    log_set_level("info");
    print(log_info("ts"));
}"""
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output)
        assert out.startswith("[")
