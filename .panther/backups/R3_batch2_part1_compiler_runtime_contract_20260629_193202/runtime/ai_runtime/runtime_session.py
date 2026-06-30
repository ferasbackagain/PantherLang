#!/usr/bin/env python3
from __future__ import annotations

import uuid
from dataclasses import dataclass, asdict
from typing import Any

from runtime.ai_runtime.runtime_context import RuntimeContext


@dataclass
class RuntimeSession:
    session_id: str
    context: RuntimeContext

    def to_dict(self) -> dict[str, Any]:
        return {
            "session_id": self.session_id,
            "context": self.context.to_dict()
        }


class RuntimeSessionManager:
    def __init__(self) -> None:
        self.sessions: dict[str, RuntimeSession] = {}

    def create_session(self) -> RuntimeSession:
        sid = str(uuid.uuid4())
        session = RuntimeSession(session_id=sid, context=RuntimeContext(session_id=sid))
        self.sessions[sid] = session
        return session

    def get_session(self, session_id: str) -> RuntimeSession:
        if session_id not in self.sessions:
            raise KeyError(f"Runtime session not found: {session_id}")
        return self.sessions[session_id]
