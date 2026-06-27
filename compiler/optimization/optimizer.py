#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any


class PantherOptimizerError(Exception):
    pass


def stable_fingerprint(source_text: str, options: dict[str, Any] | None = None) -> str:
    payload = {
        "source": source_text,
        "options": options or {},
        "optimizer": "phase6.19",
    }
    data = json.dumps(payload, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(data).hexdigest()


def optimize_ir(ir: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    optimized: list[dict[str, Any]] = []
    removed_noops = 0

    for item in ir:
        if item.get("op") == "NOOP":
            removed_noops += 1
            continue
        optimized.append(item)

    metadata = {
        "optimizer_phase": "6.19",
        "deterministic": True,
        "removed_noops": removed_noops,
        "input_nodes": len(ir),
        "output_nodes": len(optimized),
    }
    return optimized, metadata


def write_compile_cache(cache_dir: Path, fingerprint: str, report: dict[str, Any]) -> Path:
    cache_dir.mkdir(parents=True, exist_ok=True)
    out = cache_dir / f"{fingerprint}.json"
    out.write_text(json.dumps(report, indent=2, sort_keys=True), encoding="utf-8")
    return out
