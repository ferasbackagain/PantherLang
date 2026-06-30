from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

@dataclass
class PantherField:
    name: str
    type_name: str
    required: bool = False
    nullable: bool = False
    default: Optional[Any] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class PantherModel:
    name: str
    fields: List[PantherField] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def field_names(self) -> List[str]:
        return [field.name for field in self.fields]

@dataclass
class PantherAPI:
    method: str
    path: str
    model: Optional[str] = None
    action: Optional[str] = None
    public: bool = False
    secure_role: Optional[str] = None

@dataclass
class PantherPage:
    name: str
    title: str = ""
    tables: List[str] = field(default_factory=list)
    forms: List[str] = field(default_factory=list)

@dataclass
class PantherAgent:
    name: str
    purpose: str = ""
    tools: List[str] = field(default_factory=list)
    memory: str = "none"

@dataclass
class PantherApplication:
    name: str
    version: str = "0.1"
    models: List[PantherModel] = field(default_factory=list)
    apis: List[PantherAPI] = field(default_factory=list)
    pages: List[PantherPage] = field(default_factory=list)
    agents: List[PantherAgent] = field(default_factory=list)
