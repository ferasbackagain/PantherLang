from __future__ import annotations

import sys
from pathlib import Path
from typing import Any, BinaryIO

from .messages import DAPRequest, event, response
from .protocol import DAPProtocolError, read_message
from .session import DebugSession
from .transport import Transport


class PantherDebugAdapter:
    """Minimal real Debug Adapter Protocol implementation for H4.1 Part 1."""

    def __init__(self, transport: Transport, root: Path | None = None) -> None:
        self.transport = transport
        self.session = DebugSession(root=root or Path.cwd())
        self._seq = 1
        self._running = True

    def next_seq(self) -> int:
        value = self._seq
        self._seq += 1
        return value

    def send(self, message: dict[str, Any]) -> None:
        self.transport.write(message)

    def handle_initialize(self, request: DAPRequest) -> None:
        self.session.apply_initialize_arguments(request.arguments)
        self.send(response(self.next_seq(), request, body=self.session.capabilities()))
        self.send(event(self.next_seq(), "initialized", {"adapterID": "pantherlang"}))

    def handle_disconnect(self, request: DAPRequest) -> None:
        self.session.disconnected = True
        self.send(response(self.next_seq(), request, body={"terminated": True}))
        self.send(event(self.next_seq(), "terminated", {"restart": False}))
        self.send(event(self.next_seq(), "exited", {"exitCode": 0}))
        self._running = False

    def handle_configuration_done(self, request: DAPRequest) -> None:
        self.send(response(self.next_seq(), request, body={"configured": True}))

    def handle_threads(self, request: DAPRequest) -> None:
        self.send(response(self.next_seq(), request, body={"threads": [{"id": 1, "name": "Panther Main Thread"}]}))

    def handle_unknown(self, request: DAPRequest) -> None:
        self.send(response(self.next_seq(), request, success=False, message=f"Unsupported DAP command in H4.1 Part 1: {request.command}"))

    def handle_request(self, raw: dict[str, Any]) -> None:
        if raw.get("type") != "request":
            return
        request = DAPRequest.from_raw(raw)
        handlers = {
            "initialize": self.handle_initialize,
            "disconnect": self.handle_disconnect,
            "configurationDone": self.handle_configuration_done,
            "threads": self.handle_threads,
        }
        handlers.get(request.command, self.handle_unknown)(request)

    def serve(self) -> int:
        while self._running:
            try:
                raw = self.transport.read()
            except EOFError:
                break
            except DAPProtocolError as exc:
                self.send(event(self.next_seq(), "output", {"category": "stderr", "output": f"DAP protocol error: {exc}\n"}))
                return 2
            self.handle_request(raw)
        self.transport.close()
        return 0
