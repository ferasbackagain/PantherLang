import time
import tempfile
from pathlib import Path

from compiler.security.sandbox import (
    Sandbox,
    SandboxViolation,
    ResourceLimits,
    ReadOnlySandbox,
    SafeExecSandbox,
)


def test_sandbox_time_limit():
    limits = ResourceLimits(max_execution_time=0.01)
    sandbox = Sandbox(limits)
    with sandbox:
        time.sleep(0.02)
        try:
            sandbox.check_time_limit()
            assert False, "Expected SandboxViolation"
        except SandboxViolation:
            pass


def test_sandbox_no_time_violation():
    limits = ResourceLimits(max_execution_time=10.0)
    sandbox = Sandbox(limits)
    with sandbox:
        sandbox.check_time_limit()


def test_sandbox_file_read_denied():
    limits = ResourceLimits(allowed_read_paths={"/tmp"})
    sandbox = Sandbox(limits)
    with sandbox:
        try:
            sandbox.check_file_read("/etc/passwd")
            assert False, "Expected SandboxViolation"
        except SandboxViolation:
            pass


def test_sandbox_file_read_allowed():
    limits = ResourceLimits(allowed_read_paths={"/tmp"})
    sandbox = Sandbox(limits)
    with sandbox:
        path = sandbox.check_file_read("/tmp/test.txt")
        assert path.endswith("test.txt")


def test_sandbox_network_denied():
    limits = ResourceLimits(network_allowed=False)
    sandbox = Sandbox(limits)
    with sandbox:
        try:
            sandbox.check_network()
            assert False, "Expected SandboxViolation"
        except SandboxViolation:
            pass


def test_sandbox_network_allowed():
    limits = ResourceLimits(network_allowed=True)
    sandbox = Sandbox(limits)
    with sandbox:
        sandbox.check_network()


def test_sandbox_exec_denied():
    limits = ResourceLimits(exec_allowed=False)
    sandbox = Sandbox(limits)
    with sandbox:
        try:
            sandbox.check_exec()
            assert False, "Expected SandboxViolation"
        except SandboxViolation:
            pass


def test_sandbox_file_size_exceeded():
    limits = ResourceLimits(max_file_size_mb=1)
    sandbox = Sandbox(limits)
    with sandbox:
        try:
            sandbox.check_file_size(2 * 1024 * 1024)
            assert False, "Expected SandboxViolation"
        except SandboxViolation:
            pass


def test_sandbox_file_size_ok():
    limits = ResourceLimits(max_file_size_mb=10)
    sandbox = Sandbox(limits)
    with sandbox:
        sandbox.check_file_size(1024)


def test_sandbox_sensitive_path_denied():
    sandbox = Sandbox()
    with sandbox:
        try:
            sandbox.check_file_read("/etc/shadow")
            assert False, "Expected SandboxViolation"
        except SandboxViolation:
            pass


def test_readonly_sandbox():
    sandbox = ReadOnlySandbox(allowed_paths=["/tmp"])
    with sandbox:
        sandbox.check_file_read("/tmp/test.txt")
        try:
            sandbox.check_network()
            assert False, "Expected SandboxViolation"
        except SandboxViolation:
            pass


def test_sandbox_context_manager():
    limits = ResourceLimits(max_execution_time=10.0)
    with Sandbox(limits) as sandbox:
        sandbox.check_time_limit()


def test_sandbox_denied_path_patterns():
    sandbox = Sandbox()
    with sandbox:
        checks = [
            ("/etc/shadow", True),
            ("/etc/passwd", True),
            ("/tmp/foo.txt", False),
        ]
        for path, should_deny in checks:
            try:
                sandbox.check_file_read(path)
                if should_deny:
                    assert False, f"Expected SandboxViolation for {path}"
            except SandboxViolation:
                if not should_deny:
                    assert False, f"Unexpected SandboxViolation for {path}"
