from dataclasses import dataclass, field
from typing import Any, Dict, List


@dataclass
class IRField:
    name: str
    type_name: str
    required: bool = False
    nullable: bool = False
    default: Any = None

    def to_dict(self):
        return {
            "kind": "IRField",
            "name": self.name,
            "type": self.type_name,
            "required": self.required,
            "nullable": self.nullable,
            "default": self.default,
        }


@dataclass
class IRModel:
    name: str
    fields: List[IRField] = field(default_factory=list)

    def to_dict(self):
        return {
            "kind": "IRModel",
            "name": self.name,
            "fields": [field.to_dict() for field in self.fields],
        }


@dataclass
class IRProgram:
    name: str = "PantherProgram"
    models: List[IRModel] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self):
        return {
            "kind": "IRProgram",
            "name": self.name,
            "models": [model.to_dict() for model in self.models],
            "metadata": self.metadata,
        }
