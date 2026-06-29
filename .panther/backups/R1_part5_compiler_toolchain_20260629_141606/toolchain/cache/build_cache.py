#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any


class BuildCache:
    def __init__(self, root: Path | None = None):
        self.root = root or Path.cwd()
        self.cache_dir = self.root / ".panther_cache" / "build"
        self.cache_dir.mkdir(parents=True, exist_ok=True)

    def fingerprint(self, source: Path, profile: str = "debug") -> str:
        data = source.read_bytes()
        payload = profile.encode() + b"\0" + data
        return hashlib.sha256(payload).hexdigest()

    def cache_file(self, source: Path, profile: str = "debug") -> Path:
        return self.cache_dir / f"{source.stem}.{profile}.json"

    def status(self, source: Path, profile: str = "debug") -> dict[str, Any]:
        source = source.expanduser().resolve()
        digest = self.fingerprint(source, profile)
        cache = self.cache_file(source, profile)
        previous = None
        if cache.exists():
            previous = json.loads(cache.read_text(encoding="utf-8"))
        hit = previous is not None and previous.get("fingerprint") == digest
        return {
            "ok": True,
            "phase": "9.6",
            "source": str(source),
            "profile": profile,
            "fingerprint": digest,
            "cache": str(cache),
            "hit": hit,
            "changed": not hit,
        }

    def update(self, source: Path, profile: str = "debug", artifact: str | None = None) -> dict[str, Any]:
        state = self.status(source, profile)
        payload = {
            "fingerprint": state["fingerprint"],
            "source": state["source"],
            "profile": profile,
            "artifact": artifact,
        }
        Path(state["cache"]).write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
        state["updated"] = True
        return state

    def clear(self) -> dict[str, Any]:
        removed = 0
        if self.cache_dir.exists():
            for item in self.cache_dir.glob("*.json"):
                item.unlink()
                removed += 1
        return {"ok": True, "phase": "9.6", "removed": removed}
