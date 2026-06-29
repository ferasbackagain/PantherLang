from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_agent_execute() -> None:
    from runtime.agents.agent import PantherAgent
    agent = PantherAgent(name="TestAgent", role="tester", goal="verify")
    result = agent.execute("run-test")
    assert result["ok"] is True
    assert result["agent"] == "TestAgent"
    assert result["context"]["memory"]["TestAgent.last_instruction"]["value"] == "run-test"


def test_registry_duplicate_fails() -> None:
    from runtime.agents.agent import PantherAgent, PantherAgentError
    from runtime.agents.agent_registry import AgentRegistry
    registry = AgentRegistry()
    registry.register(PantherAgent(name="A"))
    try:
        registry.register(PantherAgent(name="A"))
        raise AssertionError("duplicate agent should fail")
    except PantherAgentError:
        pass


def test_agent_api_demo() -> None:
    proc = subprocess.run(
        [sys.executable, "runtime/agents/agent_api.py", "demo"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    data = json.loads(proc.stdout)
    assert data["ok"] is True
    assert data["demo"] == "agent-execution-engine"
