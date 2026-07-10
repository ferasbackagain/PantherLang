#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


class PantherMemoryError(Exception):
    pass


@dataclass
class MemoryRecord:
    key: str
    scope: str
    value: Any
    trust: str
    created_at: str
    tags: list[str]
    audit: dict[str, Any]


class LocalMemoryStore:
    """Deterministic local memory store for PantherLang Phase 5.3."""

    VALID_SCOPES = {"local", "project", "agent", "session"}
    VALID_TRUST = {"low", "medium", "high", "verified"}

    def __init__(self, path: Path) -> None:
        self.path = path
        self.records: list[MemoryRecord] = []
        self.load()

    def load(self) -> None:
        if not self.path.exists():
            self.records = []
            return
        raw = json.loads(self.path.read_text(encoding="utf-8"))
        self.records = [MemoryRecord(**item) for item in raw.get("records", [])]

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        data = {
            "phase": "5.3",
            "engine": "local_deterministic_memory",
            "records": [asdict(r) for r in self.records],
        }
        self.path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")

    def put(self, key: str, scope: str, value: Any, trust: str, tags: list[str]) -> MemoryRecord:
        if scope not in self.VALID_SCOPES:
            raise PantherMemoryError(f"Invalid scope: {scope}")
        if trust not in self.VALID_TRUST:
            raise PantherMemoryError(f"Invalid trust: {trust}")
        if not key.strip():
            raise PantherMemoryError("Memory key cannot be empty")

        record = MemoryRecord(
            key=key,
            scope=scope,
            value=value,
            trust=trust,
            created_at=datetime.now(timezone.utc).isoformat(),
            tags=tags,
            audit={
                "created_by": "panther-memory-runtime",
                "phase": "5.3",
                "external_api_used": False,
                "deterministic": True,
            },
        )

        self.records = [r for r in self.records if not (r.key == key and r.scope == scope)]
        self.records.append(record)
        self.save()
        return record

    def get(self, key: str, scope: str | None = None) -> list[MemoryRecord]:
        return [
            r for r in self.records
            if r.key == key and (scope is None or r.scope == scope)
        ]

    def search(self, query: str, scope: str | None = None, limit: int = 5) -> list[MemoryRecord]:
        q = query.lower().strip()
        hits: list[tuple[int, MemoryRecord]] = []
        for record in self.records:
            if scope is not None and record.scope != scope:
                continue
            haystack = " ".join([
                record.key,
                str(record.value),
                " ".join(record.tags),
                record.trust,
                record.scope,
            ]).lower()
            score = haystack.count(q) if q else 0
            if score > 0:
                hits.append((score, record))
        hits.sort(key=lambda item: (-item[0], item[1].key))
        return [record for _, record in hits[:limit]]

    def context(self, query: str, scope: str | None = None, limit: int = 5) -> dict[str, Any]:
        hits = self.search(query=query, scope=scope, limit=limit)
        assembled = "\n".join(f"- [{r.scope}/{r.trust}] {r.key}: {r.value}" for r in hits)
        return {
            "phase": "5.3",
            "context_mode": "deterministic_keyword",
            "query": query,
            "scope": scope,
            "record_count": len(hits),
            "assembled_context": assembled,
            "records": [asdict(r) for r in hits],
            "external_api_used": False,
        }


def parse_tags(raw: str) -> list[str]:
    return [item.strip() for item in raw.split(",") if item.strip()]


def print_json(data: Any) -> None:
    print(json.dumps(data, ensure_ascii=False))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-memory-runtime")
    parser.add_argument("--store", default=".panther_memory/memory_store.json")

    sub = parser.add_subparsers(dest="cmd", required=True)

    put_p = sub.add_parser("put")
    put_p.add_argument("--key", required=True)
    put_p.add_argument("--scope", default="project")
    put_p.add_argument("--value", required=True)
    put_p.add_argument("--trust", default="medium")
    put_p.add_argument("--tags", default="")

    get_p = sub.add_parser("get")
    get_p.add_argument("--key", required=True)
    get_p.add_argument("--scope")

    search_p = sub.add_parser("search")
    search_p.add_argument("--query", required=True)
    search_p.add_argument("--scope")
    search_p.add_argument("--limit", type=int, default=5)

    ctx_p = sub.add_parser("context")
    ctx_p.add_argument("--query", required=True)
    ctx_p.add_argument("--scope")
    ctx_p.add_argument("--limit", type=int, default=5)

    demo_p = sub.add_parser("demo")
    demo_p.add_argument("--reset", action="store_true")

    args = parser.parse_args(argv)
    store_path = Path(args.store)

    if args.cmd == "demo" and args.reset and store_path.exists():
        store_path.unlink()

    store = LocalMemoryStore(store_path)

    try:
        if args.cmd == "put":
            print_json(asdict(store.put(
                key=args.key,
                scope=args.scope,
                value=args.value,
                trust=args.trust,
                tags=parse_tags(args.tags),
            )))
            return 0

        if args.cmd == "get":
            print_json([asdict(r) for r in store.get(key=args.key, scope=args.scope)])
            return 0

        if args.cmd == "search":
            print_json([asdict(r) for r in store.search(query=args.query, scope=args.scope, limit=args.limit)])
            return 0

        if args.cmd == "context":
            print_json(store.context(query=args.query, scope=args.scope, limit=args.limit))
            return 0

        if args.cmd == "demo":
            store.put("project.goal", "project", "Build PantherLang into an AI-native programming language.", "verified", ["pantherlang", "goal", "ai"])
            store.put("phase.5.3", "project", "Memory and Context Engine provides deterministic context retrieval.", "verified", ["phase5", "memory", "context"])
            store.put("runtime.rule", "project", "Every professional phase must include practical tests and negative tests.", "high", ["testing", "quality", "policy"])
            result = store.context(query="context", scope="project", limit=5)
            print_json({
                "demo": "phase5.3-memory-context",
                "ok": result["record_count"] >= 1,
                "practical_result": result["assembled_context"],
                "record_count": result["record_count"],
                "external_api_used": False
            })
            return 0

    except PantherMemoryError as exc:
        print_json({
            "ok": False,
            "error": str(exc),
            "phase": "5.3"
        })
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
