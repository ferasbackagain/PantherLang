"""Phase C11 — Security Hardening Tests

Tests security boundaries of all new APIs added in C1-C10:
- Path traversal prevention (storage, filesystem)
- Injection resistance
- Information leakage prevention
"""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from compiler.runtime import execute_source


class TestStoragePathTraversal:
    """Verify storage path traversal is blocked."""

    def test_traversal_basic(self):
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    print(to_string(storage_exists(s, "../etc/passwd")));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "false"

    def test_traversal_deep(self):
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    print(to_string(storage_exists(s, "../../../../etc/passwd")));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "false"

    def test_traversal_encoded(self):
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    print(to_string(storage_exists(s, "foo/../../../etc/passwd")));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "false"

    def test_traversal_absolute(self):
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    print(to_string(storage_exists(s, "/etc/passwd")));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "false"

    def test_traversal_put_blocked(self):
        """Put should fail on traversal attempt."""
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    print(to_string(storage_put(s, "../evil.txt", "hack")));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "false"

    def test_traversal_list_blocked(self):
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    storage_put(s, "ok.txt", "safe");
    let items = storage_list(s, "..");
    print(to_string(len(items)));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "0"


class TestFilesystemPathTraversal:
    """Verify filesystem functions prevent traversal where appropriate."""

    def test_fs_join_no_traversal(self):
        """fs_join concatenates paths (does not resolve ..)."""
        src = """panther main {
    print(fs_join("/safe", "../etc/passwd"));
}"""
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output).strip()
        assert out == "/safe/../etc/passwd" or out == "/safe\\..\\etc/passwd"

    def test_fs_basename_safe(self):
        """fs_basename should only return the last component."""
        src = """panther main {
    print(fs_basename("../../etc/passwd"));
}"""
        result = execute_source(src)
        assert result.error is None
        assert "".join(result.captured_output).strip() == "passwd"


class TestSQLInjection:
    """Verify SQL parameterization prevents injection."""

    def test_sqli_blocked(self):
        """SQL injection via parameters should not work."""
        src = """panther main {
    let ok = db_open(":memory:");
    db_execute(ok, "CREATE TABLE t (id int, name text)");
    // Injection attempt via parameter — should be quoted
    let evil = "1; DROP TABLE t; --";
    db_execute(ok, "INSERT INTO t VALUES (?, ?)", [1, evil]);
    let r = db_query(ok, "SELECT name FROM t WHERE id = 1");
    // Table should still exist, injection should have been a literal string
    print(to_string(len(r)));
}"""
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output).strip()
        assert "1" in out  # one row with the malicious string as data


class TestInfoLeakage:
    """Verify no accidental information leakage."""

    def test_error_messages_no_paths(self):
        """Error messages should not leak internal file paths."""
        src = """panther main {
    let x = 1 / 0;
}"""
        result = execute_source(src)
        assert result.error is not None
        err = str(result.error)
        # Should not contain absolute file paths
        assert "/home/" not in err
        assert "pantherlang/" not in err
