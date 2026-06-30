from __future__ import annotations

from dataclasses import fields
from enum import Enum
from typing import Any

from .base import ASTNode, SourceLocation


def ast_to_dict(value: Any) -> Any:
    if isinstance(value, ASTNode):
        data: dict[str, Any] = {"type": value.node_type}
        if value.location is not None:
            data["location"] = value.location.to_dict()
        for field in fields(value):
            if field.name in ("location", "metadata"):
                continue
            data[field.name] = ast_to_dict(getattr(value, field.name))
        if value.metadata:
            data["metadata"] = ast_to_dict(value.metadata)
        return data
    if isinstance(value, SourceLocation):
        return value.to_dict()
    if isinstance(value, tuple) or isinstance(value, list):
        return [ast_to_dict(item) for item in value]
    if isinstance(value, dict):
        return {str(k): ast_to_dict(v) for k, v in value.items()}
    if isinstance(value, Enum):
        return value.value
    return value
