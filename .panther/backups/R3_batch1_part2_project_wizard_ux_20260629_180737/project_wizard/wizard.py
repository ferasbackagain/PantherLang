from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import shutil


TEMPLATE_MAP = {
    "console": "console_app",
    "web": "web_app",
    "api": "api_app",
    "ai": "ai_app",
}


@dataclass(frozen=True)
class ProjectResult:
    name: str
    template: str
    destination: Path
    files_created: int


def available_templates() -> list[str]:
    return sorted(TEMPLATE_MAP.keys())


def _safe_project_name(name: str) -> str:
    cleaned = "".join(ch for ch in name.strip() if ch.isalnum() or ch in ("-", "_"))
    if not cleaned:
        raise ValueError("project name cannot be empty")
    return cleaned


def _render_text(text: str, project_name: str) -> str:
    return text.replace("{{PROJECT_NAME}}", project_name)


def create_project(name: str, template: str = "console", destination: str | Path = ".") -> ProjectResult:
    project_name = _safe_project_name(name)
    template_key = template.strip().lower()
    if template_key not in TEMPLATE_MAP:
        raise ValueError(f"unknown template: {template}. Available: {', '.join(available_templates())}")

    root = Path(__file__).resolve().parents[2]
    template_dir = root / "project_templates" / TEMPLATE_MAP[template_key]
    if not template_dir.exists():
        raise FileNotFoundError(f"template directory not found: {template_dir}")

    dest_root = Path(destination).resolve()
    project_dir = dest_root / project_name
    if project_dir.exists():
        raise FileExistsError(f"destination already exists: {project_dir}")

    files_created = 0
    for src in template_dir.rglob("*"):
        rel = src.relative_to(template_dir)
        dst = project_dir / rel
        if src.is_dir():
            dst.mkdir(parents=True, exist_ok=True)
            continue

        dst.parent.mkdir(parents=True, exist_ok=True)
        try:
            text = src.read_text(encoding="utf-8")
            dst.write_text(_render_text(text, project_name), encoding="utf-8")
        except UnicodeDecodeError:
            shutil.copy2(src, dst)
        files_created += 1

    return ProjectResult(project_name, template_key, project_dir, files_created)
