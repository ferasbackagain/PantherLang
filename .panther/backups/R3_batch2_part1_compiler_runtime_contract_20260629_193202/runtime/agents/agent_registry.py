#!/usr/bin/env python3
from __future__ import annotations

from runtime.agents.agent import PantherAgent, PantherAgentError


class AgentRegistry:
    def __init__(self) -> None:
        self.agents: dict[str, PantherAgent] = {}

    def register(self, agent: PantherAgent) -> PantherAgent:
        if agent.name in self.agents:
            raise PantherAgentError(f"Agent already registered: {agent.name}")
        self.agents[agent.name] = agent
        return agent

    def get(self, name: str) -> PantherAgent:
        if name not in self.agents:
            raise PantherAgentError(f"Agent not found: {name}")
        return self.agents[name]

    def list_agents(self) -> list[dict[str, str]]:
        return [
            {"name": agent.name, "role": agent.role, "goal": agent.goal, "agent_id": agent.agent_id}
            for agent in self.agents.values()
        ]
