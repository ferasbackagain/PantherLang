#!/usr/bin/env python3
from __future__ import annotations

from typing import Any

from runtime.agents.agent import PantherAgent
from runtime.agents.agent_registry import AgentRegistry


class AgentExecutor:
    def __init__(self, registry: AgentRegistry | None = None) -> None:
        self.registry = registry or AgentRegistry()

    def register_agent(self, name: str, role: str = "worker", goal: str = "") -> PantherAgent:
        return self.registry.register(PantherAgent(name=name, role=role, goal=goal))

    def execute(self, name: str, instruction: str) -> dict[str, Any]:
        agent = self.registry.get(name)
        return agent.execute(instruction)

    def demo(self) -> dict[str, Any]:
        self.register_agent("ResearchAgent", role="researcher", goal="Analyze PantherLang runtime")
        result = self.execute("ResearchAgent", "phase7.3.demo")
        return {
            "ok": True,
            "phase": "7.3",
            "demo": "agent-execution-engine",
            "agents": self.registry.list_agents(),
            "result": result,
            "network_used": False,
            "external_api_used": False,
        }
