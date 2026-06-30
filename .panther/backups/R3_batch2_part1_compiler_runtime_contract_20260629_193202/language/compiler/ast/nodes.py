from dataclasses import dataclass, field
from typing import List


@dataclass
class ASTField:
    name: str
    type_name: str
    required: bool = False
    default: str = ""


@dataclass
class ASTModel:
    name: str
    fields: List[ASTField] = field(default_factory=list)


@dataclass
class ASTApp:
    name: str
    version: str = "0.5"


@dataclass
class ASTApi:
    method: str
    path: str


@dataclass
class ASTPage:
    name: str
    title: str = ""
    table: str = ""


@dataclass
class ASTAgent:
    name: str
    purpose: str = ""
    memory: str = "none"
    tools: List[str] = field(default_factory=list)


@dataclass
class ASTProgram:
    app: ASTApp | None = None
    models: List[ASTModel] = field(default_factory=list)
    apis: List[ASTApi] = field(default_factory=list)
    pages: List[ASTPage] = field(default_factory=list)
    agents: List[ASTAgent] = field(default_factory=list)
