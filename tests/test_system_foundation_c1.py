"""Phase C1 — System Foundation Tests

Tests for system introspection functions:
- system_home, system_temp, system_ppid, system_exit
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from compiler.runtime import execute_source


class TestSystemHome:
    def test_system_home_returns_string(self):
        """system_home() should return a non-empty string."""
        src = 'panther main {\n    print(system_home());\n}\n'
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output)
        assert len(out) > 0
        assert "/" in out


class TestSystemTemp:
    def test_system_temp_returns_string(self):
        """system_temp() should return a non-empty string."""
        src = 'panther main {\n    print(system_temp());\n}\n'
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output)
        assert len(out) > 0


class TestSystemPPID:
    def test_system_ppid_returns_int(self):
        """system_ppid() should return a positive integer."""
        src = 'panther main {\n    print(to_string(system_ppid()));\n}\n'
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output).strip()
        assert out.isdigit()
        assert int(out) > 0


class TestSystemExit:
    def test_system_exit_0_raises_systemexit(self):
        """system_exit(0) should raise SystemExit(0)."""
        src = 'panther main {\n    system_exit(0);\n}\n'
        with pytest.raises(SystemExit) as exc_info:
            execute_source(src)
        assert exc_info.value.code == 0

    def test_system_exit_1_raises_systemexit(self):
        """system_exit(1) should raise SystemExit(1)."""
        src = 'panther main {\n    system_exit(1);\n}\n'
        with pytest.raises(SystemExit) as exc_info:
            execute_source(src)
        assert exc_info.value.code == 1

    def test_system_exit_default_code_zero(self):
        """system_exit() without args should raise SystemExit(0)."""
        src = 'panther main {\n    system_exit();\n}\n'
        with pytest.raises(SystemExit) as exc_info:
            execute_source(src)
        assert exc_info.value.code == 0


class TestSysEnv:
    def test_system_env_path(self):
        """system_env('PATH') should return a non-empty string."""
        src = 'panther main {\n    print(system_env("PATH"));\n}\n'
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output).strip()
        assert len(out) > 0

    def test_system_env_default(self):
        """system_env with default should return default for missing var."""
        src = 'panther main {\n    print(system_env("NONEXISTENT_VAR_XYZ", "default_val"));\n}\n'
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output).strip()
        assert out == "default_val"

    def test_system_env_missing_no_default(self):
        """system_env without default for missing var should return empty string."""
        src = 'panther main {\n    print(system_env("NONEXISTENT_VAR_XYZ"));\n}\n'
        result = execute_source(src)
        assert result.error is None
        out = "".join(result.captured_output).strip()
        assert out == ""
