from __future__ import annotations

import platform as _platform
from dataclasses import dataclass, field
from typing import Any


@dataclass(frozen=True)
class HostCapability:
    name: str
    description: str
    supported_platforms: tuple[str, ...] = ("linux", "windows", "darwin")
    requires_network: bool = False
    requires_subprocess: bool = False
    requires_root: bool = False


_CAPABILITIES: dict[str, HostCapability] = {}


def register_capability(cap: HostCapability) -> None:
    _CAPABILITIES[cap.name] = cap


def is_capability_available(name: str) -> bool:
    cap = _CAPABILITIES.get(name)
    if cap is None:
        return False
    current = _platform.system().lower()
    if current not in cap.supported_platforms:
        return False
    return True


def list_capabilities() -> list[dict[str, Any]]:
    return [
        {
            "name": cap.name,
            "description": cap.description,
            "available": is_capability_available(cap.name),
            "requires_network": cap.requires_network,
        }
        for cap in sorted(_CAPABILITIES.values(), key=lambda c: c.name)
    ]


def get_capability(name: str) -> dict[str, Any] | None:
    cap = _CAPABILITIES.get(name)
    if cap is None:
        return None
    return {
        "name": cap.name,
        "description": cap.description,
        "available": is_capability_available(cap.name),
        "requires_network": cap.requires_network,
    }
