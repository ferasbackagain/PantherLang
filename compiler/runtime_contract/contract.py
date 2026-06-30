from __future__ import annotations

from dataclasses import dataclass, asdict
from typing import Literal


COMPILER_RUNTIME_VERSION = "0.1.0-r3-b2"
SUPPORTED_ENTRYPOINTS = ("main", "web", "api", "ai", "test")


@dataclass(frozen=True)
class CompilerRuntimeContract:
    version: str
    source_extensions: tuple[str, ...]
    manifest_file: str
    entrypoints: tuple[str, ...]
    stages: tuple[str, ...]
    build_artifact_format: str


def get_contract() -> CompilerRuntimeContract:
    return CompilerRuntimeContract(
        version=COMPILER_RUNTIME_VERSION,
        source_extensions=(".panther", ".pan"),
        manifest_file="panther.toml",
        entrypoints=SUPPORTED_ENTRYPOINTS,
        stages=(
            "lex",
            "parse",
            "ast",
            "semantic_check",
            "ir",
            "runtime_execute",
            "artifact_emit",
        ),
        build_artifact_format="panther-build-json-v1",
    )


def contract_as_dict() -> dict:
    return asdict(get_contract())
