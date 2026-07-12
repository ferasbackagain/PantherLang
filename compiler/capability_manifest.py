from __future__ import annotations

import platform as _platform
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from compiler.stdlib import get_stdlib_functions

# Standard Library 2.0 Implementation Classifications
PANTHER_IMPLEMENTED = "PANTHER_IMPLEMENTED"
HOST_BACKED = "HOST_BACKED"
NATIVE_BACKED = "NATIVE_BACKED"
PYTHON_BACKED = "PYTHON_BACKED"
PYTHON_BOOTSTRAP_BACKED = "PYTHON_BOOTSTRAP_BACKED"
EXTERNAL_LIBRARY_BACKED = "EXTERNAL_LIBRARY_BACKED"
EXTERNAL_TOOL_BACKED = "EXTERNAL_TOOL_BACKED"
STUB = "STUB"
UNSUPPORTED = "UNSUPPORTED"


@dataclass(frozen=True)
class HostCapability:
    name: str
    description: str
    supported_platforms: tuple[str, ...] = ("linux", "windows", "darwin")
    requires_network: bool = False
    requires_subprocess: bool = False
    requires_root: bool = False
    category: str = "host_abi"


@dataclass(frozen=True)
class StdlibFunctionCapability:
    name: str
    description: str
    arity: tuple[int, int]
    category: str = "stdlib"
    implementation: str = "python"
    fallback: str | None = None
    classification: str = PYTHON_BACKED
    return_type: str = "any"
    package: str = ""
    platforms: tuple[str, ...] = ("linux", "windows", "darwin")
    stability: str = "stable"


@dataclass(frozen=True)
class SelfHostedModule:
    name: str
    path: str
    functions: tuple[str, ...]
    category: str = "selfhost"


@dataclass(frozen=True)
class PackageCapability:
    name: str
    path: str
    functions: tuple[str, ...]
    classification: str = PANTHER_IMPLEMENTED
    category: str = "package"


@dataclass(frozen=True)
class NativeBackend:
    name: str
    library: str
    functions: tuple[str, ...]
    supported_platforms: tuple[str, ...] = ("linux",)
    category: str = "native"


_CAPABILITIES: dict[str, HostCapability] = {}
_STDLIB_FUNCTIONS: dict[str, StdlibFunctionCapability] = {}
_SELFHOSTED_MODULES: dict[str, SelfHostedModule] = {}
_NATIVE_BACKENDS: dict[str, NativeBackend] = {}
_PACKAGES: dict[str, PackageCapability] = {}


def register_capability(cap: HostCapability) -> None:
    _CAPABILITIES[cap.name] = cap


def register_stdlib_function(cap: StdlibFunctionCapability) -> None:
    _STDLIB_FUNCTIONS[cap.name] = cap


def register_selfhosted_module(mod: SelfHostedModule) -> None:
    _SELFHOSTED_MODULES[mod.name] = mod


def register_native_backend(backend: NativeBackend) -> None:
    _NATIVE_BACKENDS[backend.name] = backend


def register_package(pkg: PackageCapability) -> None:
    _PACKAGES[pkg.name] = pkg


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
            "category": cap.category,
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
        "category": cap.category,
    }


def list_stdlib_functions() -> list[dict[str, Any]]:
    return [
        {
            "name": fn.name,
            "description": fn.description,
            "arity": fn.arity,
            "category": fn.category,
            "implementation": fn.implementation,
            "fallback": fn.fallback,
            "classification": fn.classification,
            "return_type": fn.return_type,
            "package": fn.package,
            "platforms": list(fn.platforms),
            "stability": fn.stability,
        }
        for fn in sorted(_STDLIB_FUNCTIONS.values(), key=lambda f: f.name)
    ]


def list_selfhosted_modules() -> list[dict[str, Any]]:
    return [
        {
            "name": mod.name,
            "path": mod.path,
            "functions": list(mod.functions),
            "category": mod.category,
        }
        for mod in sorted(_SELFHOSTED_MODULES.values(), key=lambda m: m.name)
    ]


def list_native_backends() -> list[dict[str, Any]]:
    return [
        {
            "name": backend.name,
            "library": backend.library,
            "functions": list(backend.functions),
            "supported_platforms": list(backend.supported_platforms),
            "category": backend.category,
        }
        for backend in sorted(_NATIVE_BACKENDS.values(), key=lambda b: b.name)
    ]


def list_packages() -> list[dict[str, Any]]:
    return [
        {
            "name": pkg.name,
            "path": pkg.path,
            "functions": list(pkg.functions),
            "classification": pkg.classification,
            "category": pkg.category,
        }
        for pkg in sorted(_PACKAGES.values(), key=lambda p: p.name)
    ]


def get_manifest() -> dict[str, Any]:
    """Return the complete unified capability manifest."""
    return {
        "host_abilities": list_capabilities(),
        "stdlib_functions": list_stdlib_functions(),
        "selfhosted_modules": list_selfhosted_modules(),
        "native_backends": list_native_backends(),
        "packages": list_packages(),
        "platform": _platform.system().lower(),
    }


def init_manifest() -> None:
    pass


# Auto-populate stdlib functions from the existing registry
def _populate_stdlib_functions() -> None:
    for name, fn in get_stdlib_functions().items():
        if name in _STDLIB_FUNCTIONS:
            continue
        impl = "python"
        fallback = None
        classification = PYTHON_BACKED
        if name in ("sha256", "read_file", "write_file", "file_exists", "mkdir", "time_now", "sleep"):
            impl = "native"
            fallback = "python"
            classification = NATIVE_BACKED
        if name in ("tcp_connect",):
            impl = "native"
            fallback = "python"
            classification = NATIVE_BACKED
        if name.startswith("_concurrent_") or name.startswith("_async_"):
            classification = PYTHON_BOOTSTRAP_BACKED
        _STDLIB_FUNCTIONS[name] = StdlibFunctionCapability(
            name=name,
            description=fn.doc or fn.signature if hasattr(fn, 'signature') else fn.doc,
            arity=fn.arity,
            category="stdlib",
            implementation=impl,
            fallback=fallback,
            classification=classification,
        )


# Auto-populate self-hosted modules
def _populate_selfhosted_modules() -> None:
    selfhost_dir = Path(__file__).resolve().parents[1] / "stdlib" / "selfhost"
    if selfhost_dir.exists():
        import re
        for path in sorted(selfhost_dir.glob("*.pan")):
            mod_name = path.stem
            text = path.read_text(encoding="utf-8")
            fn_names = tuple(re.findall(r"fn\s+(\w+)\s*\(", text))
            _SELFHOSTED_MODULES[mod_name] = SelfHostedModule(
                name=mod_name,
                path=str(path.relative_to(Path(__file__).resolve().parents[2])),
                functions=fn_names,
                category="selfhost",
            )


def _populate_packages() -> None:
    pkg_dir = Path(__file__).resolve().parents[1] / "stdlib" / "panther"
    if pkg_dir.exists():
        import re
        for pkg_path in sorted(pkg_dir.iterdir()):
            if pkg_path.is_dir():
                init_file = pkg_path / "__init__.pan"
                if init_file.exists():
                    text = init_file.read_text(encoding="utf-8")
                    fn_names = tuple(re.findall(r"fn\s+(\w+)\s*\(", text))
                    classification = PANTHER_IMPLEMENTED
                    if pkg_path.name in ("concurrent", "async"):
                        classification = PYTHON_BOOTSTRAP_BACKED
                    _PACKAGES[pkg_path.name] = PackageCapability(
                        name=pkg_path.name,
                        path=str(init_file.relative_to(Path(__file__).resolve().parents[2])),
                        functions=fn_names,
                        classification=classification,
                        category="package",
                    )


# Auto-populate native backends
def _populate_native_backends() -> None:
    backends = {
        "filesystem": NativeBackend("filesystem", "libc", ("open", "read", "write", "close", "mkdir", "unlink", "rename", "access"), ("linux",)),
        "crypto": NativeBackend("crypto", "libcrypto", ("SHA256",), ("linux",)),
        "time": NativeBackend("time", "libc", ("clock_gettime", "nanosleep"), ("linux",)),
        "socket": NativeBackend("socket", "libc", ("socket", "connect", "close", "setsockopt"), ("linux",)),
    }
    for name, backend in backends.items():
        _NATIVE_BACKENDS[name] = backend


# Initialize on import
_populate_stdlib_functions()
_populate_selfhosted_modules()
_populate_packages()
_populate_native_backends()
