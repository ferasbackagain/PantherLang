#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from typing import Any


class PantherDistributedError(Exception):
    pass


@dataclass
class Node:
    id: str
    status: str
    capabilities: list[str]


@dataclass
class Task:
    id: str
    required_capability: str
    payload: Any
    status: str
    audit: dict[str, Any]


@dataclass
class Result:
    task_id: str
    node_id: str
    ok: bool
    output: Any
    audit: dict[str, Any]


class LocalDistributedRuntime:
    def __init__(self, max_nodes: int = 100, max_tasks: int = 5000) -> None:
        self.max_nodes = max_nodes
        self.max_tasks = max_tasks
        self.nodes: dict[str, Node] = {}
        self.tasks: list[Task] = []
        self.results: list[Result] = []
        self.failures = 0

    def now(self) -> str:
        return datetime.now(timezone.utc).isoformat()

    def audit(self) -> dict[str, Any]:
        return {
            "phase": "5.7",
            "runtime": "local_deterministic_distributed",
            "external_api_used": False,
            "network_used": False,
            "deterministic": True,
            "created_at": self.now(),
        }

    def add_node(self, node_id: str, capabilities: list[str]) -> Node:
        if not node_id.strip():
            raise PantherDistributedError("Node id cannot be empty")
        if len(self.nodes) >= self.max_nodes and node_id not in self.nodes:
            raise PantherDistributedError("Node limit exceeded")
        if not capabilities:
            raise PantherDistributedError("Node must have at least one capability")
        node = Node(id=node_id, status="ready", capabilities=capabilities)
        self.nodes[node_id] = node
        return node

    def add_task(self, task_id: str, required_capability: str, payload: Any) -> Task:
        if not task_id.strip():
            raise PantherDistributedError("Task id cannot be empty")
        if len(self.tasks) >= self.max_tasks:
            raise PantherDistributedError("Task limit exceeded")
        if not required_capability.strip():
            raise PantherDistributedError("Task required capability cannot be empty")
        task = Task(
            id=task_id,
            required_capability=required_capability,
            payload=payload,
            status="queued",
            audit=self.audit(),
        )
        self.tasks.append(task)
        return task

    def eligible_nodes(self, capability: str) -> list[Node]:
        return [
            n for n in sorted(self.nodes.values(), key=lambda x: x.id)
            if n.status == "ready" and capability in n.capabilities
        ]

    def execute_task(self, task: Task, node: Node) -> Result:
        task.status = "running"
        node.status = "busy"

        # Deterministic local execution model.
        if isinstance(task.payload, (int, float)):
            output = task.payload * 2
        elif isinstance(task.payload, str):
            output = task.payload.upper()
        else:
            output = task.payload

        task.status = "completed"
        node.status = "ready"
        result = Result(
            task_id=task.id,
            node_id=node.id,
            ok=True,
            output=output,
            audit=self.audit(),
        )
        self.results.append(result)
        return result

    def run(self) -> dict[str, Any]:
        if not self.nodes:
            raise PantherDistributedError("No nodes registered")
        for task in self.tasks:
            if task.status != "queued":
                continue
            nodes = self.eligible_nodes(task.required_capability)
            if not nodes:
                task.status = "failed"
                self.failures += 1
                continue
            # Deterministic round-robin based on completed results count.
            node = nodes[len(self.results) % len(nodes)]
            self.execute_task(task, node)

        return {
            "phase": "5.7",
            "ok": self.failures == 0,
            "nodes": [asdict(n) for n in sorted(self.nodes.values(), key=lambda x: x.id)],
            "tasks": [asdict(t) for t in self.tasks],
            "results": [asdict(r) for r in self.results],
            "scheduled_tasks": len(self.tasks),
            "completed_tasks": len(self.results),
            "failed_tasks": self.failures,
            "external_api_used": False,
            "network_used": False,
            "deterministic": True,
        }

    def demo(self) -> dict[str, Any]:
        self.add_node("node-a", ["text", "math"])
        self.add_node("node-b", ["text"])
        self.add_node("node-c", ["math"])
        self.add_task("task-1", "text", "panther distributed execution")
        self.add_task("task-2", "math", 21)
        self.add_task("task-3", "text", "ai native runtime")
        return self.run()

    def stress(self, count: int) -> dict[str, Any]:
        self.add_node("node-a", ["math"])
        self.add_node("node-b", ["math"])
        for i in range(count):
            self.add_task(f"stress-{i}", "math", i)
        return self.run()


def print_json(data: Any) -> None:
    print(json.dumps(data, ensure_ascii=False))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-distributed-runtime")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("demo")

    stress = sub.add_parser("stress")
    stress.add_argument("--count", type=int, default=50)

    neg = sub.add_parser("negative")
    neg.add_argument("--case", choices=["no-nodes", "missing-capability", "bad-node", "bad-task"], required=True)

    args = parser.parse_args(argv)

    try:
        rt = LocalDistributedRuntime()
        if args.cmd == "demo":
            print_json(rt.demo())
            return 0
        if args.cmd == "stress":
            print_json(rt.stress(args.count))
            return 0
        if args.cmd == "negative":
            if args.case == "no-nodes":
                rt.add_task("task-1", "math", 1)
                result = rt.run()
                if result["failed_tasks"] > 0:
                    raise PantherDistributedError("No eligible nodes for task execution")
            elif args.case == "missing-capability":
                rt.add_node("node-a", ["text"])
                rt.add_task("task-1", "math", 1)
                result = rt.run()
                if result["failed_tasks"] > 0:
                    raise PantherDistributedError("Missing required node capability: math")
            elif args.case == "bad-node":
                rt.add_node("", ["math"])
            elif args.case == "bad-task":
                rt.add_node("node-a", ["math"])
                rt.add_task("", "math", 1)

    except PantherDistributedError as exc:
        print_json({
            "ok": False,
            "phase": "5.7",
            "error": str(exc),
            "external_api_used": False,
            "network_used": False,
            "deterministic": True,
        })
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
