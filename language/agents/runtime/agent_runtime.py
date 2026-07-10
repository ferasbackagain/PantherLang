#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


class PantherAgentError(Exception):
    pass


@dataclass
class Agent:
    id: str
    role: str
    status: str
    permissions: list[str]


@dataclass
class AgentMessage:
    id: str
    from_agent: str
    to_agent: str
    kind: str
    payload: Any
    created_at: str
    audit: dict[str, Any]


class MultiAgentRuntime:
    VALID_ROLES = {"planner", "coder", "reviewer", "operator", "observer"}
    ALLOWED_PERMISSIONS = {"plan", "code", "review", "message", "observe"}

    def __init__(self, max_agents: int = 50, max_messages: int = 1000) -> None:
        self.max_agents = max_agents
        self.max_messages = max_messages
        self.agents: dict[str, Agent] = {}
        self.messages: list[AgentMessage] = []
        self.security_violations = 0

    def now(self) -> str:
        return datetime.now(timezone.utc).isoformat()

    def register_agent(self, agent_id: str, role: str, permissions: list[str]) -> Agent:
        if not agent_id.strip():
            raise PantherAgentError("Agent id cannot be empty")
        if role not in self.VALID_ROLES:
            raise PantherAgentError(f"Invalid role: {role}")
        if len(self.agents) >= self.max_agents and agent_id not in self.agents:
            raise PantherAgentError("Agent limit exceeded")
        invalid = [p for p in permissions if p not in self.ALLOWED_PERMISSIONS]
        if invalid:
            raise PantherAgentError(f"Invalid permission(s): {', '.join(invalid)}")

        agent = Agent(
            id=agent_id,
            role=role,
            status="ready",
            permissions=permissions,
        )
        self.agents[agent_id] = agent
        return agent

    def require_agent(self, agent_id: str) -> Agent:
        if agent_id not in self.agents:
            self.security_violations += 1
            raise PantherAgentError(f"Unregistered agent: {agent_id}")
        return self.agents[agent_id]

    def require_permission(self, agent: Agent, permission: str) -> None:
        if permission not in agent.permissions:
            self.security_violations += 1
            raise PantherAgentError(f"Agent {agent.id} lacks permission: {permission}")

    def send_message(self, from_agent: str, to_agent: str, kind: str, payload: Any) -> AgentMessage:
        sender = self.require_agent(from_agent)
        self.require_agent(to_agent)
        self.require_permission(sender, "message")

        if len(self.messages) >= self.max_messages:
            raise PantherAgentError("Message limit exceeded")

        msg = AgentMessage(
            id=f"msg-{len(self.messages) + 1}",
            from_agent=from_agent,
            to_agent=to_agent,
            kind=kind,
            payload=payload,
            created_at=self.now(),
            audit={
                "phase": "5.4",
                "runtime": "local_deterministic_multi_agent",
                "external_api_used": False,
                "deterministic": True,
            },
        )
        self.messages.append(msg)
        return msg

    def run_planner_coder_reviewer_demo(self) -> dict[str, Any]:
        self.register_agent("planner", "planner", ["plan", "message"])
        self.register_agent("coder", "coder", ["code", "message"])
        self.register_agent("reviewer", "reviewer", ["review", "message"])

        self.send_message(
            "planner",
            "coder",
            "task.plan",
            "Create a PantherLang memory-context demo function.",
        )
        self.send_message(
            "coder",
            "reviewer",
            "task.code",
            "fn demo_context() { return \"Memory and agents connected\" }",
        )
        self.send_message(
            "reviewer",
            "planner",
            "task.review",
            "APPROVED: deterministic workflow completed.",
        )

        return {
            "phase": "5.4",
            "workflow": "planner-coder-reviewer",
            "ok": True,
            "agents_executed": len(self.agents),
            "messages_exchanged": len(self.messages),
            "security_violations": self.security_violations,
            "runtime_failures": 0,
            "final_output": "Reviewer approved PantherLang multi-agent workflow.",
            "external_api_used": False,
            "agents": [asdict(a) for a in self.agents.values()],
            "messages": [asdict(m) for m in self.messages],
        }

    def stress(self, count: int) -> dict[str, Any]:
        if count > self.max_messages:
            raise PantherAgentError("Stress count exceeds max_messages")
        self.register_agent("observer-a", "observer", ["observe", "message"])
        self.register_agent("observer-b", "observer", ["observe", "message"])
        for i in range(count):
            self.send_message("observer-a", "observer-b", "stress.ping", f"ping-{i}")
        return {
            "phase": "5.4",
            "ok": True,
            "stress_messages": count,
            "messages_exchanged": len(self.messages),
            "security_violations": self.security_violations,
            "external_api_used": False,
        }


def print_json(data: Any) -> None:
    print(json.dumps(data, ensure_ascii=False))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-agent-runtime")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("demo")

    stress_p = sub.add_parser("stress")
    stress_p.add_argument("--count", type=int, default=25)

    bad_p = sub.add_parser("negative")
    bad_p.add_argument("--case", choices=["unregistered", "permission", "bad-role"], required=True)

    args = parser.parse_args(argv)
    runtime = MultiAgentRuntime()

    try:
        if args.cmd == "demo":
            print_json(runtime.run_planner_coder_reviewer_demo())
            return 0

        if args.cmd == "stress":
            print_json(runtime.stress(args.count))
            return 0

        if args.cmd == "negative":
            if args.case == "unregistered":
                runtime.register_agent("planner", "planner", ["plan", "message"])
                runtime.send_message("planner", "missing-agent", "bad", "payload")
            elif args.case == "permission":
                runtime.register_agent("observer", "observer", ["observe"])
                runtime.register_agent("reviewer", "reviewer", ["review", "message"])
                runtime.send_message("observer", "reviewer", "bad", "payload")
            elif args.case == "bad-role":
                runtime.register_agent("x", "illegal-role", ["message"])

    except PantherAgentError as exc:
        print_json({
            "ok": False,
            "phase": "5.4",
            "error": str(exc),
            "security_violations": runtime.security_violations,
            "external_api_used": False,
        })
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
