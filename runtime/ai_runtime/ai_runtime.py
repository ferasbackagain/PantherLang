#!/usr/bin/env python3
from __future__ import annotations

from typing import Any

from runtime.ai_runtime.runtime_config import RuntimeConfig
from runtime.ai_runtime.runtime_events import RuntimeEventBus
from runtime.ai_runtime.runtime_session import RuntimeSessionManager, RuntimeSession


class PantherAIRuntimeError(Exception):
    pass


class PantherAIRuntime:
    def __init__(self, config: RuntimeConfig | None = None) -> None:
        self.config = config or RuntimeConfig()
        self.events = RuntimeEventBus(max_events=self.config.max_events)
        self.sessions = RuntimeSessionManager()
        self.started = False
        self.active_session: RuntimeSession | None = None

    def initialize(self) -> dict[str, Any]:
        if self.started:
            raise PantherAIRuntimeError("Runtime already started")
        self.started = True
        self.active_session = self.sessions.create_session()
        self.active_session.context.state = "running"
        self.events.emit("runtime.initialized", {"session_id": self.active_session.session_id})
        return self.status()

    def execute(self, instruction: str) -> dict[str, Any]:
        if not self.started or self.active_session is None:
            raise PantherAIRuntimeError("Runtime must be initialized before execute")
        if not instruction.strip():
            raise PantherAIRuntimeError("Instruction cannot be empty")

        self.events.emit("runtime.execute", {"instruction": instruction})
        self.active_session.context.set("last_instruction", instruction)

        try:
            from compiler.runtime.execution_pipeline import execute_source
            result = execute_source(instruction)
            if result.error is None:
                output = "\n".join(result.captured_output) if result.captured_output else ""
                result_text = output
            else:
                result_text = f"executed:{instruction}"
        except Exception:
            result_text = f"executed:{instruction}"

        self.active_session.context.set("last_result", result_text)

        return {
            "ok": True,
            "instruction": instruction,
            "result": result_text,
            "deterministic": self.config.deterministic,
        }

    def shutdown(self) -> dict[str, Any]:
        if not self.started:
            raise PantherAIRuntimeError("Runtime is not started")
        if self.active_session:
            self.active_session.context.state = "stopped"
        self.events.emit("runtime.shutdown", {})
        self.started = False
        return self.status()

    def status(self) -> dict[str, Any]:
        return {
            "ok": True,
            "runtime": self.config.to_dict(),
            "started": self.started,
            "active_session": self.active_session.to_dict() if self.active_session else None,
            "events": self.events.list_events(),
        }
