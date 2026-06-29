from __future__ import annotations

import socket
import sys
from typing import Any, BinaryIO

from .protocol import encode_message, read_message


class Transport:
    def read(self) -> dict[str, Any]:
        raise NotImplementedError

    def write(self, message: dict[str, Any]) -> None:
        raise NotImplementedError

    def close(self) -> None:
        pass


class StdioTransport(Transport):
    def __init__(self, stdin: BinaryIO | None = None, stdout: BinaryIO | None = None) -> None:
        self.stdin = stdin or sys.stdin.buffer
        self.stdout = stdout or sys.stdout.buffer

    def read(self) -> dict[str, Any]:
        return read_message(self.stdin)

    def write(self, message: dict[str, Any]) -> None:
        self.stdout.write(encode_message(message))
        self.stdout.flush()


class SocketTransport(Transport):
    def __init__(self, conn: socket.socket) -> None:
        self.conn = conn
        self.reader = conn.makefile("rb")
        self.writer = conn.makefile("wb")

    def read(self) -> dict[str, Any]:
        return read_message(self.reader)

    def write(self, message: dict[str, Any]) -> None:
        self.writer.write(encode_message(message))
        self.writer.flush()

    def close(self) -> None:
        try:
            self.reader.close()
            self.writer.close()
        finally:
            self.conn.close()
