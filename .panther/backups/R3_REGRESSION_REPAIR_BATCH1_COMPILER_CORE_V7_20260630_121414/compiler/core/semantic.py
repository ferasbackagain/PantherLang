from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

@dataclass
class Field:
    name: str
    type: str
    required: bool = False
    unique: bool = False
    default: Any = None

@dataclass
class DataModel:
    name: str
    fields: List[Field] = field(default_factory=list)

@dataclass
class APIEndpoint:
    method: str
    path: str
    action: str = ""
    model: str = ""
    public: bool = False
    secure_role: Optional[str] = None

@dataclass
class UIPage:
    name: str
    title: str = ""
    hero: str = ""
    tables: List[str] = field(default_factory=list)
    forms: List[str] = field(default_factory=list)

@dataclass
class PantherSemanticModel:
    app_name: str = "PantherApp"
    version: str = "0.5"
    targets: List[str] = field(default_factory=list)
    description: str = ""
    data_models: List[DataModel] = field(default_factory=list)
    apis: List[APIEndpoint] = field(default_factory=list)
    pages: List[UIPage] = field(default_factory=list)
    workflows: List[str] = field(default_factory=list)
    agents: List[str] = field(default_factory=list)
    devices: List[str] = field(default_factory=list)
    tasks: List[str] = field(default_factory=list)
    security: Dict[str, Any] = field(default_factory=dict)
    deploy: Dict[str, Any] = field(default_factory=lambda: {"target": "local", "port": 7777})

    def to_dict(self):
        return {
            "app_name": self.app_name,
            "version": self.version,
            "targets": self.targets,
            "description": self.description,
            "data_models": [{"name": m.name, "fields": [f.__dict__ for f in m.fields]} for m in self.data_models],
            "apis": [a.__dict__ for a in self.apis],
            "pages": [p.__dict__ for p in self.pages],
            "workflows": self.workflows,
            "agents": self.agents,
            "devices": self.devices,
            "tasks": self.tasks,
            "security": self.security,
            "deploy": self.deploy,
        }

def _statement_value(children, key):
    for child in children:
        if child.kind == "statement" and child.name == key:
            return str(child.value)
    return ""

def _strip_quotes(value):
    value = str(value).strip()
    if value.startswith('"') and value.endswith('"'):
        return value[1:-1]
    return value

def _parse_list_from_statement(text):
    if not text:
        return []
    parts = text.split(maxsplit=1)
    if len(parts) < 2:
        return []
    return [p.strip() for p in parts[1].split(",") if p.strip()]

def _parse_field(text):
    parts = text.split()
    if len(parts) < 2:
        return None
    default = None
    if "=" in parts:
        idx = parts.index("=")
        if idx + 1 < len(parts):
            default = _strip_quotes(parts[idx + 1])
    return Field(
        name=parts[0],
        type=parts[1],
        required="required" in parts,
        unique="unique" in parts,
        default=default,
    )

def _model_name_from_path(path, model_names):
    clean = path.strip("/").lower()
    for model in model_names:
        if clean in {model.lower(), model.lower() + "s"}:
            return model
    if clean.endswith("s"):
        guess = clean[:-1]
        for model in model_names:
            if model.lower() == guess:
                return model
    return ""

def build_semantic_model(program) -> PantherSemanticModel:
    semantic = PantherSemanticModel()

    for node in program.nodes:
        if node.kind == "app":
            semantic.app_name = node.name
            version_stmt = _statement_value(node.children, "version")
            if version_stmt and len(version_stmt.split(maxsplit=1)) > 1:
                semantic.version = _strip_quotes(version_stmt.split(maxsplit=1)[1])
            targets_stmt = _statement_value(node.children, "targets") or _statement_value(node.children, "target")
            semantic.targets = _parse_list_from_statement(targets_stmt)
            desc_stmt = _statement_value(node.children, "description")
            if desc_stmt and len(desc_stmt.split(maxsplit=1)) > 1:
                semantic.description = _strip_quotes(desc_stmt.split(maxsplit=1)[1])

        elif node.kind == "data":
            fields = []
            for child in node.children:
                if child.kind == "statement":
                    field = _parse_field(str(child.value))
                    if field:
                        fields.append(field)
            semantic.data_models.append(DataModel(name=node.name, fields=fields))

    model_names = [m.name for m in semantic.data_models]

    for node in program.nodes:
        if node.kind == "api":
            endpoint = APIEndpoint(
                method=node.meta.get("method", ""),
                path=node.meta.get("path", ""),
                model=_model_name_from_path(node.meta.get("path", ""), model_names),
            )
            for child in node.children:
                txt = str(child.value)
                if child.name == "public":
                    endpoint.public = True
                elif child.name == "secure":
                    parts = txt.split()
                    endpoint.secure_role = parts[1] if len(parts) > 1 else "authenticated"
                elif child.name == "return":
                    endpoint.action = "list"
                elif child.name == "create":
                    endpoint.action = "create"
                    parts = txt.split()
                    if len(parts) >= 2:
                        endpoint.model = parts[1]
            semantic.apis.append(endpoint)

        elif node.kind == "ui":
            page = UIPage(name=node.meta.get("page", node.name.replace("page ", "")))
            for child in node.children:
                txt = str(child.value)
                if child.name == "title" and len(txt.split(maxsplit=1)) > 1:
                    page.title = _strip_quotes(txt.split(maxsplit=1)[1])
                elif child.name == "hero" and len(txt.split(maxsplit=1)) > 1:
                    page.hero = _strip_quotes(txt.split(maxsplit=1)[1])
                elif child.name == "table":
                    parts = txt.split()
                    if len(parts) > 1:
                        page.tables.append(parts[1])
                elif child.name == "form":
                    parts = txt.split()
                    if len(parts) > 1:
                        page.forms.append(parts[1])
            semantic.pages.append(page)

        elif node.kind == "workflow":
            semantic.workflows.append(node.name)
        elif node.kind == "agent":
            semantic.agents.append(node.name)
        elif node.kind == "device":
            semantic.devices.append(node.name)
        elif node.kind == "task":
            semantic.tasks.append(node.name)
        elif node.kind == "security":
            for child in node.children:
                semantic.security[child.name] = child.value
        elif node.kind == "deploy":
            for child in node.children:
                parts = str(child.value).split()
                if len(parts) >= 2:
                    if parts[0] == "port":
                        semantic.deploy["port"] = int(parts[1])
                    elif parts[0] == "target":
                        semantic.deploy["target"] = parts[1]

    return semantic
