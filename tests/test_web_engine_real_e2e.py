"""End-to-end test: real PantherLang web server with real HTTP connections."""

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


def _find_free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def test_web_server_lifecycle():
    """Full lifecycle: start → listen → serve → stop → port released."""
    port = 8080

    # Write a temp .pan file with the desired port
    source = f"""
panther main {{
    print "PantherLang Web Server";
}}

web {{
    route GET "/" {{
        return "Hello from PantherLang";
    }}

    route GET "/health" {{
        return {{status: "healthy"}};
    }}

    route POST "/api/echo" {{
        return {{echo: "received", ok: true}};
    }}
}}
"""
    with tempfile.NamedTemporaryFile(mode="w", suffix=".pan", delete=False) as f:
        f.write(source)
        tmp_path = f.name

    try:
        # Start the server in a subprocess with a process group for proper signal handling
        proc = subprocess.Popen(
            [sys.executable, "-m", "cli.panther_cli", "run", tmp_path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            preexec_fn=os.setsid,
        )

        # Wait for server to become ready
        ready = False
        for _ in range(50):
            try:
                with urllib.request.urlopen(f"http://127.0.0.1:{port}/", timeout=1) as resp:
                    if resp.status == 200:
                        ready = True
                        break
            except (ConnectionRefusedError, OSError, urllib.error.HTTPError):
                time.sleep(0.2)

        assert ready, "Server did not become ready within 6 seconds"

        # 1. GET / → 200
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/", timeout=3) as resp:
            assert resp.status == 200, f"Expected 200, got {resp.status}"
            body = resp.read().decode()
            assert "Hello from PantherLang" in body, f"Unexpected body: {body}"

        # 2. GET /health → 200 + JSON
        with urllib.request.urlopen(f"http://127.0.0.1:{port}/health", timeout=3) as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["status"] == "healthy"

        # 3. POST /api/echo → 200 + JSON
        req = urllib.request.Request(
            f"http://127.0.0.1:{port}/api/echo",
            data=json.dumps({"message": "test"}).encode(),
            method="POST",
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=3) as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["ok"] is True

        # 4. GET /nonexistent → 404
        try:
            urllib.request.urlopen(f"http://127.0.0.1:{port}/nonexistent", timeout=3)
            assert False, "Should have raised HTTPError"
        except urllib.error.HTTPError as e:
            assert e.code == 404

        # 5. Verify listener is still up
        with socket.create_connection(("127.0.0.1", port), timeout=1) as s:
            pass

        # Stop the server - send SIGTERM to process group
        os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            proc.wait()

        # 6. Verify port is released
        time.sleep(0.5)
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=1):
                assert False, "Port should be released after stop"
            raise Exception("connection should have failed")
        except (ConnectionRefusedError, OSError):
            pass  # Expected — port released

        # 7. Verify port is reusable
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            s.bind(("127.0.0.1", port))
            s.listen(1)
            # success if no error

        print("test_web_server_lifecycle: PASS")
    finally:
        os.unlink(tmp_path)


def test_web_server_without_web_block():
    """Source without web block should not start a server."""
    source = 'panther main { print "no web block"; }'
    with tempfile.NamedTemporaryFile(mode="w", suffix=".pan", delete=False) as f:
        f.write(source)
        tmp_path = f.name

    try:
        result = subprocess.run(
            [sys.executable, "-m", "cli.panther_cli", "run", tmp_path],
            capture_output=True,
            text=True,
            timeout=10,
        )
        assert result.returncode == 0
        assert "no web block" in result.stdout

        print("test_web_server_without_web_block: PASS")
    finally:
        os.unlink(tmp_path)


def test_web_server_multiple_routes():
    """Multiple routes with different paths."""
    port = 8080
    source = """
panther main { print "multi-route server"; }

web {
    route GET "/a" { return "route-a"; }
    route GET "/b" { return "route-b"; }
    route POST "/c" { return {posted: true}; }
}
"""
    with tempfile.NamedTemporaryFile(mode="w", suffix=".pan", delete=False) as f:
        f.write(source)
        tmp_path = f.name

    try:
        proc = subprocess.Popen(
            [sys.executable, "-m", "cli.panther_cli", "run", tmp_path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            preexec_fn=os.setsid,
        )

        # Wait for server to become ready
        ready = False
        for _ in range(60):
            try:
                with urllib.request.urlopen(f"http://127.0.0.1:{port}/a", timeout=1) as resp:
                    if resp.status == 200:
                        ready = True
                        break
            except (ConnectionRefusedError, OSError, urllib.error.HTTPError):
                time.sleep(0.2)

        assert ready, "Server did not become ready within 12 seconds"

        with urllib.request.urlopen(f"http://127.0.0.1:{port}/a", timeout=3) as resp:
            assert resp.status == 200
            assert resp.read().decode() == "route-a"

        with urllib.request.urlopen(f"http://127.0.0.1:{port}/b", timeout=3) as resp:
            assert resp.status == 200
            assert resp.read().decode() == "route-b"

        req = urllib.request.Request(f"http://127.0.0.1:{port}/c", data=b"", method="POST")
        with urllib.request.urlopen(req, timeout=3) as resp:
            assert resp.status == 200
            data = json.loads(resp.read().decode())
            assert data["posted"] is True

        os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            proc.wait()

        print("test_web_server_multiple_routes: PASS")
    finally:
        os.unlink(tmp_path)
