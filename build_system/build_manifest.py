#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path


def write_build_manifest(project_root: Path, source: Path, artifact: Path, mode: str) -> Path:
    manifest = {
        "phase": "9.1",
        "mode": mode,
        "project_root": str(project_root),
        "source": str(source),
        "artifact": str(artifact),
        "production_build": True,
        "local_build_output": True
    }
    out = project_root / "build" / "build_manifest.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
    return out
