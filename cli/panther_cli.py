#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shutil
import sys
from pathlib import Path
from typing import Iterable

from compiler.stdlib.selfhost import apply_selfhosted_stdlib

# Ensure the workspace root is on sys.path so the dev version of compiler/
# takes precedence over any installed site-packages version. Must happen
# before any compiler/ imports.
_workspace = os.getcwd()
if _workspace not in sys.path:
    sys.path.insert(0, _workspace)

ROOT = Path(__file__).resolve().parents[1]

_PANTHER_BANNER = """\033[1;34m  ____        _   _      _  __ _
 |  _ \\ __ _| |_| |__  / |/ _\\ | __ _ _ __
 | |_) / _` | __| '_ \\| | |_| |/ _` | '__|
 |  __/ (_| | |_| | | | |  _| | (_| | |
 |_|   \\__,_|\\__|_| |_|_|_| |_|\\__,_|_|
\033[0m
  Modern * Secure * AI-Native * Cross-Platform Programming Language
  Version {version}
  (c) Feras Khatib
"""


def _get_version() -> str:
    try:
        from panther_core.version import get_release_info
        info = get_release_info()
        return f"{info['version']} ({info['release_name']})"
    except Exception:
        return "2.0.0"


def _print_help() -> int:
    version = _get_version()
    print(_PANTHER_BANNER.format(version=version))
    print("  QUICK START")
    print("    $ panther doctor              # Verify installation")
    print("    $ panther new console myapp   # Create a new project")
    print("    $ panther run src/main.panther # Run your program")
    print()
    print("  COMMANDS")
    print("    run      <file>     Execute a PantherLang source file")
    print("    run --serve <file>  Execute and start HTTP server for web/api blocks")
    print("    build    <file>     Build a source file into an artifact")
    print("    check    <file>     Validate source file syntax")
    print("    fmt      <file>     Format / validate source file")
    print("    new      <type> <n> Create project (console, web, api, ai)")
    print("    doctor              Verify PantherLang installation")
    print("    version             Show version information")
    print("    help                Show this help message")
    print()
    print("  EXAMPLES")
    print("    panther run examples/console_hello/main.pan")
    print("    panther run examples/calculator/calc.pan")
    print("    panther new api myapi && cd myapi && panther run src/main.panther")
    print()
    print("  RESOURCES")
    print("    GitHub:  https://github.com/ferasbackagain/PantherLang")
    print("    Docs:    https://github.com/ferasbackagain/PantherLang/docs")
    print("    Website: https://pantherlang.dev")
    print()
    return 0


def _version() -> int:
    from panther_core.version import get_release_info
    info = get_release_info()
    print(f"PantherLang {info['version']} ({info['release_name']})")
    print(f"Channel: {info['release_channel']}")
    print(f"Debug Adapter: {info['debug_adapter_version']}")
    return 0


def _doctor() -> int:
    import importlib
    version = _get_version()
    print(f"PantherLang v{version}")
    print("────────────────────────────")
    checks: list[tuple[str, str, str]] = [
        ("Python", "sys", sys.version.split()[0]),
        ("compiler", "compiler.lexer", ""),
        ("runtime", "compiler.runtime", ""),
        ("stdlib", "compiler.stdlib", ""),
        ("types", "compiler.types", ""),
        ("web", "compiler.web", ""),
        ("database", "compiler.database", ""),
        ("AI", "compiler.ai", ""),
        ("security", "compiler.security", ""),
        ("package mgr", "package_manager", ""),
        ("templates", "", str(ROOT / "project_templates" / "console_app")),
    ]
    all_ok = True
    for label, module, detail in checks:
        if detail and Path(detail).exists():
            ok = True
        elif module:
            try:
                importlib.import_module(module)
                ok = True
            except Exception:
                ok = False
        else:
            ok = False
        status = "\033[32mOK\033[0m" if ok else "\033[31mFAIL\033[0m"
        if detail and ok:
            print(f"  {label:20s} {status}")
        elif module:
            extra = f" ({detail})" if detail else ""
            print(f"  {label:20s} {status}{extra}")
        if not ok:
            all_ok = False
    print("────────────────────────────")
    if all_ok:
        print("PantherLang is ready.")
    else:
        print("Some components are missing. Try reinstalling.")
    return 0 if all_ok else 1


def _ensure_project_templates() -> None:
    templates = ROOT / 'project_templates'
    for kind in ('console_app', 'web_app', 'api_app', 'ai_app'):
        base = templates / kind
        (base / 'src').mkdir(parents=True, exist_ok=True)
        (base / 'tests').mkdir(parents=True, exist_ok=True)
        (base / 'docs').mkdir(parents=True, exist_ok=True)
        (base / '.vscode').mkdir(parents=True, exist_ok=True)
        if not (base / 'src' / 'main.panther').exists():
            (base / 'src' / 'main.panther').write_text(
                'panther main {\n    print("Hello from {{PROJECT_NAME}}");\n}\n',
                encoding='utf-8',
            )
        if not (base / 'panther.toml').exists():
            (base / 'panther.toml').write_text(
                '[project]\nname = "PantherApp"\nentry = "src/main.panther"\n',
                encoding='utf-8',
            )
        if not (base / 'README.md').exists():
            (base / 'README.md').write_text('# PantherLang Project\n', encoding='utf-8')


def _run(args: list[str]) -> int:
    if not args:
        print("ERROR: run requires a source file")
        print("Usage: panther run [--serve] <file.pan|file.panther>")
        return 2
    serve_mode = "--serve" in args
    src_args = [a for a in args if a != "--serve"]
    if not src_args:
        print("ERROR: run requires a source file")
        print("Usage: panther run [--serve] <file.pan|file.panther>")
        return 2
    src = Path(src_args[0])
    if not src.is_absolute():
        src = Path.cwd() / src
    if not src.exists():
        print(f"Source file not found: {src_args[0]}")
        return 2
    source_text = src.read_text(encoding="utf-8-sig")
    if serve_mode:
        from compiler.runtime.execution_pipeline import serve_source
        result = serve_source(source_text)
    else:
        # Auto-detect web blocks — use run_source for web/api sources
        if "web {" in source_text or "api {" in source_text or "route " in source_text or "panther.web" in source_text:
            from compiler.runtime.execution_pipeline import run_source
            result = run_source(source_text)
        else:
            from compiler.runtime import execute_source
            result = execute_source(source_text)
    if result.error:
        print(f"Error: {result.error}", file=sys.stderr)
        return 1
    if result.captured_output:
        sys.stdout.write("\n".join(result.captured_output) + "\n")
    if result.return_value is not None:
        print(f"Return: {result.return_value}")
    return 0


def _build(args: list[str]) -> int:
    if not args:
        print("ERROR: build requires source file")
        return 2
    src = Path(args[0])
    if not src.is_absolute():
        src = Path.cwd() / src
    if not src.exists():
        print(f"Source file not found: {args[0]}")
        return 2
    out = None
    if "--out" in args:
        i = args.index("--out")
        if i + 1 < len(args):
            out = Path(args[i + 1])
    if out is None:
        out = Path.cwd() / "build" / (src.stem + ".sh")
    result = _run_as_artifact(src, out)
    return result


def _run_as_artifact(src: Path, out: Path) -> int:
    source_text = src.read_text(encoding="utf-8-sig")
    from compiler.runtime import execute_source
    result = execute_source(source_text)
    out.parent.mkdir(parents=True, exist_ok=True)
    lines = result.captured_output if result.captured_output else []
    body = ["#!/usr/bin/env bash", "set -euo pipefail"]
    for line in lines:
        safe = line.replace("'", "'\\''")
        body.append(f"printf '%s\\n' '{safe}'")
    out.write_text("\n".join(body) + "\n", encoding="utf-8")
    out.chmod(out.stat().st_mode | 0o755)
    if result.error:
        print(json.dumps({"ok": False, "error": result.error}, ensure_ascii=False))
        return 1
    print(json.dumps({"ok": True, "source": str(src), "artifact": str(out)}, ensure_ascii=False))
    return 0


def _check(args: list[str]) -> int:
    if not args:
        print("ERROR: check requires source file")
        return 2
    src = Path(args[0])
    if not src.is_absolute():
        src = Path.cwd() / src
    if not src.exists():
        print(f"Source file not found: {args[0]}")
        return 2
    source_text = src.read_text(encoding="utf-8-sig")
    source_text = apply_selfhosted_stdlib(source_text)
    from compiler.lexer import lex_source
    from compiler.parser import ProgramParser
    from compiler.parser.token_stream import TokenStream
    from compiler.semantic import analyze as semantic_analyze
    from compiler.security import SecurityAnalyzer
    tokens = lex_source(source_text)
    stream = TokenStream(tokens)
    parser = ProgramParser(stream)
    parse_result = parser.parse()

    all_issues: list[str] = []

    if parse_result.diagnostics:
        for d in parse_result.diagnostics:
            all_issues.append(f"  [SYNTAX] {d}")

    if parse_result.node is not None:
        diagnostics = semantic_analyze(parse_result.node)
        for d in diagnostics:
            all_issues.append(f"  [SEMANTIC] {d}")

        sec = SecurityAnalyzer()
        sec_diags = sec.analyze(parse_result.node)
        for d in sec_diags:
            all_issues.append(f"  [SECURITY] {d}")

    if all_issues:
        print(f"check: {args[0]}")
        for issue in all_issues:
            print(issue, file=sys.stderr)
        return 1

    print(f"check passed: {args[0]}")
    return 0


def _new(args: list[str]) -> int:
    if len(args) < 2:
        print("Usage: panther new <console|web|api|ai> <name>")
        return 2
    kind, name = args[0], args[1]
    mapping = {"console": "console_app", "web": "web_app", "api": "api_app", "ai": "ai_app"}
    if kind not in mapping:
        print(f"Unknown project kind: {kind}")
        print("Supported: console, web, api, ai")
        return 2
    _ensure_project_templates()
    dst = Path.cwd() / name
    if dst.exists():
        print(f"Project already exists: {dst}")
        return 2
    src_template = ROOT / "project_templates" / mapping[kind]
    shutil.copytree(src_template, dst)
    # Substitute template variables
    for file_path in dst.rglob("*"):
        if file_path.is_file():
            content = file_path.read_text(encoding="utf-8")
            content = content.replace("{{PROJECT_NAME}}", name)
            file_path.write_text(content, encoding="utf-8")
    (dst / "build").mkdir(exist_ok=True)
    (dst / "panther.toml").write_text(
        f'[project]\nname = "{name}"\ntemplate = "{kind}"\nentry = "src/main.panther"\n',
        encoding="utf-8",
    )
    print(f"Created project '{name}' at {dst}")
    print(f"  cd {name}")
    print(f"  panther run src/main.panther")
    return 0


def _fmt(args: list[str]) -> int:
    if not args:
        print("ERROR: fmt requires source file")
        return 2
    src = Path(args[0])
    if not src.is_absolute():
        src = Path.cwd() / src
    if not src.exists():
        print(f"Source file not found: {args[0]}")
        return 2
    source_text = src.read_text(encoding="utf-8-sig")
    source_text = apply_selfhosted_stdlib(source_text)
    from compiler.lexer import lex_source
    from compiler.parser import ProgramParser
    from compiler.parser.token_stream import TokenStream
    tokens = lex_source(source_text)
    stream = TokenStream(tokens)
    parser = ProgramParser(stream)
    result = parser.parse()
    if result.ok:
        print(source_text)
        return 0
    for d in result.diagnostics:
        print(f"  {d}", file=sys.stderr)
    return 1


def main(argv: list[str]) -> int:
    if not argv:
        return _print_help()
    cmd, args = argv[0], argv[1:]
    if cmd in ("help", "--help", "-h"):
        return _print_help()
    elif cmd in ("version", "--version", "-v"):
        return _version()
    elif cmd == "doctor":
        return _doctor()
    elif cmd == "run":
        return _run(args)
    elif cmd == "build":
        return _build(args)
    elif cmd == "check":
        return _check(args)
    elif cmd == "new":
        return _new(args)
    elif cmd == "fmt":
        return _fmt(args)
    else:
        print(f"Unknown command: {cmd}")
        print("Run 'panther help' for usage.")
        return 2


def main_entry() -> None:
    raise SystemExit(main(sys.argv[1:]))


if __name__ == "__main__":
    main_entry()
