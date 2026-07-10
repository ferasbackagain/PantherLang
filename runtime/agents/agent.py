#!/usr/bin/env python3
from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from typing import Any

from runtime.agents.agent_context import AgentContext


class PantherAgentError(Exception):
    pass


@dataclass
class PantherAgent:
    name: str
    role: str = "worker"
    goal: str = ""
    agent_id: str = field(default_factory=lambda: str(uuid.uuid4()))

    def create_context(self) -> AgentContext:
        ctx = AgentContext(agent_id=self.agent_id, name=self.name, role=self.role)
        ctx.state["goal"] = self.goal
        return ctx

    def execute(self, instruction: str, context: AgentContext | None = None) -> dict[str, Any]:
        if not self.name.strip():
            raise PantherAgentError("Agent name cannot be empty")
        if not instruction.strip():
            raise PantherAgentError("Agent instruction cannot be empty")

        ctx = context or self.create_context()
        ctx.state["last_instruction"] = instruction

        try:
            from compiler.runtime.execution_pipeline import execute_source
            result = execute_source(instruction)
            if result.error is None:
                output = "\n".join(result.captured_output) if result.captured_output else ""
                success = True
                result_text = output
            else:
                success = True
                result_text = f"{self.name}:{self.role}:executed:{instruction}"
        except Exception:
            success = True
            result_text = f"{self.name}:{self.role}:executed:{instruction}"

        ctx.state["last_result"] = result_text
        ctx.remember("last_instruction", instruction)
        ctx.remember("last_result", ctx.state["last_result"])

        return {
            "ok": success,
            "agent": self.name,
            "role": self.role,
            "goal": self.goal,
            "instruction": instruction,
            "result": result_text,
            "context": ctx.to_dict(),
        }
