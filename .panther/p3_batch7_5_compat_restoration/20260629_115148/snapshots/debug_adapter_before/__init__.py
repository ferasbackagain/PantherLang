"""PantherLang Canonical Debug Adapter Rebuild.

This package is built cleanly from the P-2 canonical contract.
It must not depend on historical monkey patches or drifting runtime code.
"""

from .protocol import (
    DAPProtocolError,
    DAPEncodedMessage,
    encode_message,
    decode_message,
    read_message,
)

__all__ = [
    "DAPProtocolError",
    "DAPEncodedMessage",
    "encode_message",
    "decode_message",
    "read_message",
]
