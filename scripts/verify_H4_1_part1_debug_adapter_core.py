#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any, BinaryIO

ROOT = Path(__file__).resolve().parents[1]


def encode(message: dict[str, Any]) -> bytes:
    payload = json.dumps(message, separators=(",", ":")).encode("utf-8")
    return f"Content-Length: {len(payload)}\r\n\r\n".encode("ascii") + payload


def read_message(stream: BinaryIO) -> dict[str, Any]:
    length = None
    while True:
        line = stream.readline()
        if line == b"":
            raise EOFError("adapter closed before response")
        if line in (b"\r\n", b"\n"):
            break
        k, v = line.decode("ascii").strip().split(":", 1)
        if k.lower() == "content-length":
            length = int(v.strip())
    if length is None:
        raise AssertionError("missing Content-Length")
    payload = stream.read(length)
    return json.loads(payload.decode("utf-8"))


def assert_true(value: bool, msg: str) -> None:
    if not value:
        raise AssertionError(msg)


def main() -> int:
    required = [
        ROOT / "debug_adapter" / "adapter.py",
        ROOT / "debug_adapter" / "protocol.py",
        ROOT / "debug_adapter" / "transport.py",
        ROOT / "debug_adapter" / "server.py",
        ROOT / "debug_adapter" / "launcher.py",
        ROOT / "debug_adapter" / "session.py",
        ROOT / "debug_adapter" / "messages.py",
        ROOT / "debug_adapter" / "__init__.py",
    ]
    for path in required:
        assert_true(path.exists(), f"missing {path}")

    doctor = subprocess.run([str(ROOT / "panther"), "dap", "doctor"], cwd=ROOT, text=True, capture_output=True)
    assert_true(doctor.returncode == 0, doctor.stderr or doctor.stdout)
    doctor_json = json.loads(doctor.stdout)
    assert_true(doctor_json.get("ok") is True, "doctor did not report ok")

    version = subprocess.run([str(ROOT / "panther"), "dap", "version"], cwd=ROOT, text=True, capture_output=True)
    assert_true(version.returncode == 0 and version.stdout.strip(), "version failed")

    proc = subprocess.Popen(
        [str(ROOT / "panther"), "dap", "start"],
        cwd=ROOT,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    assert proc.stdin is not None and proc.stdout is not None
    proc.stdin.write(encode({
        "seq": 1,
        "type": "request",
        "command": "initialize",
        "arguments": {
            "clientID": "panther-h4-verifier",
            "clientName": "Panther H4.1 Verification Client",
            "adapterID": "pantherlang",
            "linesStartAt1": True,
            "columnsStartAt1": True,
        },
    }))
    proc.stdin.flush()
    first = read_message(proc.stdout)
    second = read_message(proc.stdout)
    assert_true(first["type"] == "response" and first["command"] == "initialize" and first["success"] is True, f"bad initialize response: {first}")
    assert_true(first["body"].get("supportsConfigurationDoneRequest") is True, "missing capabilities")
    assert_true(second["type"] == "event" and second["event"] == "initialized", f"bad initialized event: {second}")

    proc.stdin.write(encode({"seq": 2, "type": "request", "command": "disconnect", "arguments": {"terminateDebuggee": True}}))
    proc.stdin.flush()
    third = read_message(proc.stdout)
    fourth = read_message(proc.stdout)
    fifth = read_message(proc.stdout)
    assert_true(third["type"] == "response" and third["command"] == "disconnect" and third["success"] is True, f"bad disconnect response: {third}")
    assert_true(fourth["type"] == "event" and fourth["event"] == "terminated", f"bad terminated event: {fourth}")
    assert_true(fifth["type"] == "event" and fifth["event"] == "exited", f"bad exited event: {fifth}")
    proc.stdin.close()
    rc = proc.wait(timeout=5)
    assert_true(rc == 0, f"adapter exited with {rc}: {proc.stderr.read().decode('utf-8', 'replace') if proc.stderr else ''}")

    status = ROOT / ".panther" / "phase_status" / "H4_1_part1_debug_adapter_core.json"
    status.parent.mkdir(parents=True, exist_ok=True)
    status.write_text(json.dumps({
        "phase": "H4.1 Part 1",
        "status": "verified",
        "real_dap_handshake": True,
        "commands": ["Panther dap start", "Panther dap doctor", "Panther dap version"],
        "handshake": ["initialize", "initialized", "disconnect", "terminated", "exited"],
    }, indent=2, sort_keys=True), encoding="utf-8")
    print("✅ H4.1 Part 1 verification passed: real DAP initialize/initialized/disconnect/exited handshake")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
