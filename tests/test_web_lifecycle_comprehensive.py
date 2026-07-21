"""Comprehensive web engine lifecycle tests: 405, startup failure, port reuse, resource cleanup."""

import json
import os
import signal
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
import warnings


def _start_server(source: str, timeout_sec: int = 15) -> tuple[subprocess.Popen, str]:
    """Start a PantherLang server in a subprocess, wait for readiness, return (proc, tmp_path)."""
    # Ensure the port is free first
    _ensure_port_8080_free_for_test()
    with tempfile.NamedTemporaryFile(mode="w", suffix=".pan", delete=False) as f:
        f.write(source)
        tmp_path = f.name

    proc = subprocess.Popen(
        [sys.executable, "-u", "-m", "cli.panther_cli", "run", tmp_path],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    deadline = time.time() + timeout_sec
    while time.time() < deadline:
        if proc.poll() is not None:
            # Process exited before becoming ready
            proc.wait(timeout=1)
            os.unlink(tmp_path)
            raise RuntimeError("Server process exited before becoming ready")
        try:
            with socket.create_connection(("127.0.0.1", 8080), timeout=0.5):
                return proc, tmp_path
        except (ConnectionRefusedError, OSError):
            time.sleep(0.3)

    _stop_server(proc)
    os.unlink(tmp_path)
    raise RuntimeError("Server did not become ready in time")


def _ensure_port_8080_free_for_test() -> None:
    """Ensure port 8080 is not occupied before starting a server."""
    import subprocess as _sp
    deadline = time.time() + 8
    while time.time() < deadline:
        try:
            with socket.create_connection(("127.0.0.1", 8080), timeout=0.3):
                pass
        except (ConnectionRefusedError, OSError):
            return
        # Port occupied — try to clear it
        try:
            result = _sp.run(
                ["lsof", "-ti", ":8080"],
                capture_output=True, text=True, timeout=3,
            )
            if result.returncode == 0 and result.stdout.strip():
                for pid_str in result.stdout.strip().split():
                    try:
                        pid = int(pid_str.strip())
                        os.kill(pid, signal.SIGKILL)
                    except (ValueError, ProcessLookupError, PermissionError):
                        pass
        except Exception:
            pass
        time.sleep(0.5)
    raise RuntimeError("Could not free port 8080")


def _stop_server(proc: subprocess.Popen) -> None:
    """Stop the server and wait for port 8080 to be released."""
    proc.terminate()
    try:
        proc.wait(timeout=5)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()
    # Wait for port to be released
    deadline = time.time() + 5
    while time.time() < deadline:
        try:
            with socket.create_connection(("127.0.0.1", 8080), timeout=0.3):
                time.sleep(0.3)
        except (ConnectionRefusedError, OSError):
            return


def test_405_method_not_allowed():
    """Unsupported HTTP methods on existing paths should return 405."""
    source = """
web {
    route GET "/api/data" { return {"ok": true}; }
    route POST "/api/submit" { return {"submitted": true}; }
}
"""
    with tempfile.NamedTemporaryFile(mode="w", suffix=".pan", delete=False) as f:
        f.write(source)
        tmp_path = f.name

    proc = subprocess.Popen(
        [sys.executable, "-u", "-m", "cli.panther_cli", "run", tmp_path],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        for _ in range(30):
            try:
                with socket.create_connection(("127.0.0.1", 8080), timeout=1):
                    break
            except (ConnectionRefusedError, OSError):
                time.sleep(0.3)

        req = urllib.request.Request("http://127.0.0.1:8080/api/data", method="POST")
        try:
            urllib.request.urlopen(req, timeout=3)
            assert False, "405 expected"
        except urllib.error.HTTPError as e:
            assert e.code == 405, f"Expected 405, got {e.code}"
            body = json.loads(e.read().decode())
            assert "Method Not Allowed" in str(body)

        req = urllib.request.Request("http://127.0.0.1:8080/api/submit", method="GET")
        try:
            urllib.request.urlopen(req, timeout=3)
            assert False, "405 expected"
        except urllib.error.HTTPError as e:
            assert e.code == 405

        # 404 on truly nonexistent path
        try:
            urllib.request.urlopen("http://127.0.0.1:8080/nonexistent", timeout=3)
            assert False, "404 expected"
        except urllib.error.HTTPError as e:
            assert e.code == 404

    finally:
        _stop_server(proc)
        os.unlink(tmp_path)


def test_startup_failure_port_in_use():
    """Starting a second server on the same port should fail gracefully."""
    source = 'web { route GET "/" { return "ok"; } }'

    proc1, tmp1 = _start_server(source)
    try:
        proc2 = subprocess.Popen(
            [sys.executable, "-u", "-m", "cli.panther_cli", "run", tmp1],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        try:
            stdout2, stderr2 = proc2.communicate(timeout=10)
            output = stdout2.decode() + stderr2.decode()
            assert proc2.returncode != 0, "Second server should have failed"
            assert "Address already in use" in output or "error" in output.lower()
        except subprocess.TimeoutExpired:
            proc2.kill()
            proc2.wait()
            assert False, "Second server should have exited, not blocked"
    finally:
        _stop_server(proc1)
        os.unlink(tmp1)


def test_path_parameters_e2e():
    """Route path parameters like /hello/{name} are resolved correctly."""
    source = """
web {
    route GET "/hello/{name}" {
        return {"message": "Hello", "visitor": name};
    }
}
"""
    with tempfile.NamedTemporaryFile(mode="w", suffix=".pan", delete=False) as f:
        f.write(source)
        tmp_path = f.name

    proc = subprocess.Popen(
        [sys.executable, "-u", "-m", "cli.panther_cli", "run", tmp_path],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        for _ in range(30):
            try:
                with socket.create_connection(("127.0.0.1", 8080), timeout=1):
                    break
            except (ConnectionRefusedError, OSError):
                time.sleep(0.3)

        with urllib.request.urlopen("http://127.0.0.1:8080/hello/Panther", timeout=3) as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["visitor"] == "Panther"

        with urllib.request.urlopen("http://127.0.0.1:8080/hello/Feras", timeout=3) as resp:
            data = json.loads(resp.read().decode())
            assert data["visitor"] == "Feras"

        # 404 on wrong path
        try:
            urllib.request.urlopen("http://127.0.0.1:8080/hello", timeout=3)
            assert False, "404 expected"
        except urllib.error.HTTPError as e:
            assert e.code == 404

    finally:
        _stop_server(proc)
        os.unlink(tmp_path)


def test_post_body_e2e():
    """POST with JSON body is received correctly."""
    source = """
web {
    route POST "/api/echo" {
        return {"received": true, "body": req.body};
    }
}
"""
    with tempfile.NamedTemporaryFile(mode="w", suffix=".pan", delete=False) as f:
        f.write(source)
        tmp_path = f.name

    proc = subprocess.Popen(
        [sys.executable, "-u", "-m", "cli.panther_cli", "run", tmp_path],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        for _ in range(30):
            try:
                with socket.create_connection(("127.0.0.1", 8080), timeout=1):
                    break
            except (ConnectionRefusedError, OSError):
                time.sleep(0.3)

        req = urllib.request.Request(
            "http://127.0.0.1:8080/api/echo",
            data=json.dumps({"msg": "hello world"}).encode(),
            method="POST",
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=3) as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["received"] is True

    finally:
        _stop_server(proc)
        os.unlink(tmp_path)


def test_port_reuse_after_shutdown():
    """After a clean shutdown, the port can be bound immediately."""
    source = 'web { route GET "/" { return "ok"; } }'
    proc1, tmp1 = _start_server(source)

    with urllib.request.urlopen("http://127.0.0.1:8080/", timeout=3) as r:
        assert r.status == 200

    _stop_server(proc1)
    time.sleep(0.5)

    # Second server on same port
    proc2, tmp2 = _start_server(source)
    try:
        with urllib.request.urlopen("http://127.0.0.1:8080/", timeout=3) as r:
            assert r.status == 200
    finally:
        _stop_server(proc2)
        os.unlink(tmp1)
        os.unlink(tmp2)


def test_resource_cleanup_no_warnings():
    """Running a web block produces zero ResourceWarnings."""
    source = 'web { route GET "/health" { return {"status": "ok"}; } }'
    with tempfile.NamedTemporaryFile(mode="w", suffix=".pan", delete=False) as f:
        f.write(source)
        tmp_path = f.name

    proc = subprocess.Popen(
        [sys.executable, "-W", "error::ResourceWarning", "-u", "-m", "cli.panther_cli", "run", tmp_path],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    try:
        for _ in range(30):
            try:
                with socket.create_connection(("127.0.0.1", 8080), timeout=1):
                    break
            except (ConnectionRefusedError, OSError):
                time.sleep(0.3)

        with urllib.request.urlopen("http://127.0.0.1:8080/health", timeout=3) as r:
            assert r.status == 200

        _stop_server(proc)
        stdout, stderr = proc.communicate(timeout=5)
        # Allow only the browser subprocess warning
        non_browser_warnings = [
            l for l in stderr.decode().split("\n")
            if l and "subprocess" not in l and "ResourceWarning" in l
        ]
        assert len(non_browser_warnings) == 0, f"ResourceWarnings: {non_browser_warnings}"
    finally:
        os.unlink(tmp_path)
