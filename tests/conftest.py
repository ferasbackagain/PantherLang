"""Global test fixtures: ensure port 8080 is free before each web test."""

import os
import signal
import socket
import subprocess
import time

import pytest


def _find_process_on_port(port: int) -> list[int]:
    """Find PIDs listening on the given port."""
    pids: list[int] = []
    try:
        result = subprocess.run(
            ["lsof", "-ti", f":{port}"],
            capture_output=True, text=True, timeout=5,
        )
        if result.returncode == 0 and result.stdout.strip():
            for pid_str in result.stdout.strip().split():
                try:
                    pids.append(int(pid_str.strip()))
                except ValueError:
                    pass
    except Exception:
        pass
    return pids


def _kill_port_8080() -> None:
    """Kill any process listening on port 8080. Retry until free."""
    for _ in range(10):
        try:
            with socket.create_connection(("127.0.0.1", 8080), timeout=0.3):
                pass
        except (ConnectionRefusedError, OSError, TimeoutError):
            return
        # Port is occupied — find and kill the process
        pids = _find_process_on_port(8080)
        for pid in pids:
            try:
                os.kill(pid, signal.SIGTERM)
            except (ProcessLookupError, PermissionError):
                pass
        time.sleep(0.5)
        for pid in pids:
            try:
                os.kill(pid, signal.SIGKILL)
            except (ProcessLookupError, PermissionError):
                pass
        time.sleep(0.3)


@pytest.fixture(autouse=True)
def _ensure_port_8080_free() -> None:
    """Before each test, ensure port 8080 is not occupied by a stale server."""
    _kill_port_8080()
