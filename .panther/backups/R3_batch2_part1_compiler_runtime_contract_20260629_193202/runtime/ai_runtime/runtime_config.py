#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass, asdict
from typing import Any


@dataclass
class RuntimeConfig:
    runtime_name: str = "Panther AI Runtime"
    phase: str = "7.1"
    deterministic: bool = True
    network_enabled: bool = False
    external_api_enabled: bool = False
    max_events: int = 1000

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)
