"""Phase C4 — Filesystem Completion Tests

Tests for filesystem path utilities and introspection:
- fs_is_file, fs_is_dir, fs_stat, fs_basename, fs_dirname, fs_extension
- fs_join, fs_tempdir, fs_tempfile, fs_walk
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from compiler.runtime import execute_source


class TestFSPathUtils:
    def test_basename(self):
        """fs_basename should extract the filename from a path."""
        src = 'panther main {\n    print(fs_basename("/home/user/file.txt"));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "".join(result.captured_output).strip() == "file.txt"

    def test_dirname(self):
        """fs_dirname should extract the directory from a path."""
        src = 'panther main {\n    print(fs_dirname("/home/user/file.txt"));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "".join(result.captured_output).strip() == "/home/user"

    def test_extension(self):
        """fs_extension should extract the suffix from a filename."""
        src = 'panther main {\n    print(fs_extension("file.txt"));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "".join(result.captured_output).strip() == ".txt"

    def test_extension_empty(self):
        """fs_extension should return empty string for no extension."""
        src = 'panther main {\n    print("[" + fs_extension("file") + "]");\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "".join(result.captured_output).strip() == "[]"

    def test_join(self):
        """fs_join should join path components."""
        src = 'panther main {\n    print(fs_join("/home", "user"));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "".join(result.captured_output).strip() == "/home/user"


class TestFSDetection:
    def test_is_file_true(self):
        """fs_is_file should return true for existing files."""
        src = 'panther main {\n    print(to_string(fs_is_file("compiler/stdlib/functions.py")));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "true" in "".join(result.captured_output)

    def test_is_file_false(self):
        """fs_is_file should return false for nonexistent paths."""
        src = 'panther main {\n    print(to_string(fs_is_file("nonexistent_file_xyz")));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "false" in "".join(result.captured_output)

    def test_is_dir_true(self):
        """fs_is_dir should return true for existing directories."""
        src = 'panther main {\n    print(to_string(fs_is_dir("compiler")));\n}\n'
        result = execute_source(src)
        assert result.error is None
        assert "true" in "".join(result.captured_output)


class TestFSStat:
    def test_stat_exists(self):
        """fs_stat should return metadata for existing files."""
        src = """panther main {
    let s = fs_stat("compiler/stdlib/functions.py");
    print(to_string(s["is_file"]));
    print(to_string(s["size"]));
}"""
        result = execute_source(src)
        assert result.error is None
        out = result.captured_output
        assert out[0].strip() == "true"
        assert int(out[1].strip()) > 0

    def test_stat_nonexistent(self):
        """fs_stat should return safe defaults for nonexistent paths."""
        src = """panther main {
    let s = fs_stat("nonexistent_file_xyz");
    print(to_string(s["is_file"]));
    print(to_string(s["is_dir"]));
}"""
        result = execute_source(src)
        assert result.error is None
        out = result.captured_output
        assert out[0].strip() == "false"
        assert out[1].strip() == "false"


class TestFSTemp:
    def test_tempdir_is_dir(self):
        """fs_tempdir should create a real temp directory."""
        src = """panther main {
    let d = fs_tempdir();
    print(to_string(fs_is_dir(d)));
}"""
        result = execute_source(src)
        assert result.error is None
        assert "true" in "".join(result.captured_output)

    def test_tempfile_returns_path(self):
        """fs_tempfile should return a non-empty path."""
        src = """panther main {
    let f = fs_tempfile();
    print(to_string(len(f)));
}"""
        result = execute_source(src)
        assert result.error is None
        length = "".join(result.captured_output).strip()
        assert length.isdigit()
        assert int(length) > 0


class TestFSWalk:
    def test_walk_compiler_dir(self):
        """fs_walk should find files in the compiler directory."""
        src = """panther main {
    let entries = fs_walk("compiler");
    let count = to_string(len(entries));
    print(count);
}"""
        result = execute_source(src)
        assert result.error is None
        count = "".join(result.captured_output).strip()
        assert count.isdigit()
        assert int(count) > 0
