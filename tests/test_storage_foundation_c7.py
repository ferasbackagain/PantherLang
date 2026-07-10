"""Phase C7 — Storage Foundation Tests

Tests for local filesystem-backed object storage:
- storage_open, storage_put, storage_get, storage_exists, storage_delete, storage_list
"""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from compiler.runtime import execute_source


class TestStorageBasic:
    def test_put_and_get(self):
        """Store a value and retrieve it."""
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    storage_put(s, "test.txt", "hello");
    print(storage_get(s, "test.txt"));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "hello"

    def test_put_overwrite(self):
        """Overwriting an existing key should work."""
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    storage_put(s, "key.txt", "v1");
    storage_put(s, "key.txt", "v2");
    print(storage_get(s, "key.txt"));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "v2"

    def test_get_nonexistent(self):
        """Getting a nonexistent key should return empty string."""
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    print("[" + storage_get(s, "nonexistent") + "]");
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "[]"


class TestStorageExistence:
    def test_exists_true(self):
        """Existing key should return true."""
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    storage_put(s, "x.txt", "data");
    print(to_string(storage_exists(s, "x.txt")));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "true" in "".join(result.captured_output)

    def test_exists_false(self):
        """Nonexistent key should return false."""
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    print(to_string(storage_exists(s, "nonexistent")));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "false" in "".join(result.captured_output)


class TestStorageDelete:
    def test_delete_removes_key(self):
        """Deleting a key should remove it from storage."""
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    storage_put(s, "del.txt", "data");
    print(to_string(storage_delete(s, "del.txt")));
    print(to_string(storage_exists(s, "del.txt")));
}}"""
            result = execute_source(src)
            assert result.error is None
            out = result.captured_output
            assert out[0].strip() == "true"
            assert out[1].strip() == "false"


class TestStorageList:
    def test_list_all_keys(self):
        """List should return all keys."""
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    storage_put(s, "a.txt", "1");
    storage_put(s, "b.txt", "2");
    let items = storage_list(s);
    print(to_string(len(items)));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "2"

    def test_list_with_prefix(self):
        """List with prefix should filter keys."""
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    storage_put(s, "data/a.txt", "1");
    storage_put(s, "data/b.txt", "2");
    storage_put(s, "other/c.txt", "3");
    let items = storage_list(s, "data");
    print(to_string(len(items)));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "2"

    def test_list_empty_store(self):
        """Empty store should return empty list."""
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    let items = storage_list(s);
    print(to_string(len(items)));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "0"


class TestStorageSecurity:
    def test_path_traversal_blocked(self):
        """Path traversal attempts should be blocked."""
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    print(to_string(storage_exists(s, "../../../etc/passwd")));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "false" in "".join(result.captured_output)

    def test_nested_keys(self):
        """Nested key paths should create directories."""
        with tempfile.TemporaryDirectory() as td:
            src = f"""panther main {{
    let s = storage_open("{td}");
    storage_put(s, "a/b/c/d.txt", "nested");
    print(storage_get(s, "a/b/c/d.txt"));
}}"""
            result = execute_source(src)
            assert result.error is None
            assert "".join(result.captured_output).strip() == "nested"
