from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable

from compiler.stdlib import get_stdlib_functions


ROOT = Path(__file__).resolve().parents[2]
PACKAGE_DIR = ROOT / "stdlib" / "panther"


@dataclass(frozen=True)
class PackageFunction:
    name: str
    package: str
    doc: str = ""
    arity: tuple[int, int | None] = (0, 0)
    implementation: str = "python"
    fn: Callable[..., Any] | None = None


@dataclass
class PackageInfo:
    name: str
    path: Path | None
    functions: dict[str, PackageFunction] = field(default_factory=dict)
    dependencies: list[str] = field(default_factory=list)


class PackageLoader:
    def __init__(self) -> None:
        self._packages: dict[str, PackageInfo] = {}
        self._discovered = False

    def discover_packages(self) -> dict[str, PackageInfo]:
        if self._discovered:
            return self._packages
        self._discovered = True

        if not PACKAGE_DIR.exists():
            return self._packages

        for pkg_path in sorted(PACKAGE_DIR.iterdir()):
            if not pkg_path.is_dir():
                continue
            pkg_name = pkg_path.name
            init_file = pkg_path / "__init__.pan"
            if not init_file.exists():
                continue

            pkg = PackageInfo(name=pkg_name, path=init_file)
            self._extract_functions_from_pan(pkg, init_file)
            self._packages[pkg_name] = pkg

        return self._packages

    def _extract_functions_from_pan(self, pkg: PackageInfo, path: Path) -> None:
        text = path.read_text(encoding="utf-8-sig")
        fn_pattern = re.compile(r"fn\s+(\w+)\s*\(")
        for match in fn_pattern.finditer(text):
            fn_name = match.group(1)
            pf = PackageFunction(
                name=fn_name,
                package=pkg.name,
                doc=f"{pkg.name}.{fn_name}()",
                arity=(0, 0),
                implementation="selfhost",
                fn=None,
            )
            pkg.functions[fn_name] = pf

    def resolve_import(self, module_name: str) -> PackageInfo | None:
        self.discover_packages()
        parts = module_name.split(".")
        if len(parts) >= 2 and parts[0] == "panther":
            pkg_name = parts[1]
            return self._packages.get(pkg_name)
        if module_name in self._packages:
            return self._packages[module_name]
        return None

    def get_package_function_names(self, package_name: str) -> list[str]:
        self.discover_packages()
        pkg = self._packages.get(package_name)
        if pkg is None:
            return []
        return list(pkg.functions.keys())

    def get_all_function_names(self) -> dict[str, str]:
        self.discover_packages()
        result: dict[str, str] = {}
        for pkg_name, pkg in self._packages.items():
            for fn_name in pkg.functions:
                result[fn_name] = pkg_name
        return result

    def list_packages(self) -> list[str]:
        self.discover_packages()
        return sorted(self._packages.keys())


_LOADER: PackageLoader | None = None


def get_package_loader() -> PackageLoader:
    global _LOADER
    if _LOADER is None:
        _LOADER = PackageLoader()
    return _LOADER


def reset_package_loader() -> None:
    """Reset the package loader to force re-discovery of packages."""
    global _LOADER
    _LOADER = None


def resolve_package(module_name: str) -> PackageInfo | None:
    return get_package_loader().resolve_import(module_name)


def get_package_functions() -> dict[str, PackageFunction]:
    loader = get_package_loader()
    loader.discover_packages()
    result: dict[str, PackageFunction] = {}
    for pkg in loader._packages.values():
        for fn_name, fn in pkg.functions.items():
            result[fn_name] = fn
    return result


def get_package_function_names_set() -> set[str]:
    return set(get_package_functions().keys())


def package_loader_available() -> bool:
    return PACKAGE_DIR.exists()
