from __future__ import annotations

from functools import lru_cache
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[2]
SELFHOST_DIR = ROOT / "stdlib" / "selfhost"


def _extract_first_block_body(source: str) -> str:
    """Extract the body of the first PantherLang top-level block.

    Self-hosted stdlib files are ordinary PantherLang source files that use a
    container block such as `panther main { ... }`. The loader extracts the
    statements inside that block and injects them into user programs before
    user statements execute.
    """
    start = source.find("{")
    if start < 0:
        return ""

    depth = 0
    in_string = False
    escape = False
    body_start = start + 1

    for i in range(start, len(source)):
        ch = source[i]
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            continue

        if ch == '"':
            in_string = True
            continue

        if ch == "{":
            depth += 1
            continue

        if ch == "}":
            depth -= 1
            if depth == 0:
                return source[body_start:i].strip() + "\n"

    return ""


@lru_cache(maxsize=1)
def load_selfhosted_stdlib_source() -> str:
    """Return PantherLang source statements loaded from stdlib/selfhost/*.pan."""
    if not SELFHOST_DIR.exists():
        return ""

    chunks: list[str] = []
    for path in sorted(SELFHOST_DIR.glob("*.pan")):
        text = path.read_text(encoding="utf-8-sig")
        body = _extract_first_block_body(text)
        if body:
            chunks.append("// selfhost: " + path.name + "\n" + body)

    if not chunks:
        return ""

    return "\n".join(chunks).strip() + "\n"


# More comprehensive pattern to match all block types including ai, test with arguments
_TOP_LEVEL_PATTERN = re.compile(
    r"(?P<head>^[ \t]*(?:panther[ \t]+main|web|api|ai|test|ai_agent|web_server)(?:[ \t][^{\n]*)?[ \t]*\{)",
    flags=re.IGNORECASE | re.MULTILINE,
)


def apply_selfhosted_stdlib(source: str) -> str:
    """Inject self-hosted PantherLang stdlib statements into top-level blocks.

    This is Phase 1 self-hosting: pure stdlib logic is implemented in .pan
    files and loaded before user statements. Host primitives remain registered
    by the existing runtime.
    """
    prelude = load_selfhosted_stdlib_source()
    if not prelude:
        return source

    # Avoid duplicate injection when a tool calls the loader more than once.
    if "// PANTHER_STDLIB_SELFHOST_PHASE1" in source:
        return source

    injected = "// PANTHER_STDLIB_SELFHOST_PHASE1\n" + prelude + "\n"

    def repl(match: re.Match[str]) -> str:
        return match.group("head") + "\n" + injected

    return _TOP_LEVEL_PATTERN.sub(repl, source)


def get_selfhosted_functions() -> dict[str, list]:
    """Get self-hosted function names grouped by module for LSP/docs."""
    import re as _re
    result = {}
    for path in sorted(SELFHOST_DIR.glob("*.pan")):
        text = path.read_text(encoding="utf-8-sig")
        # Extract function names using regex
        fn_names = _re.findall(r"fn\s+(\w+)\s*\(", text)
        if fn_names:
            result[path.stem] = fn_names
    return result


def clear_cache() -> None:
    """Clear all LRU caches (for testing)."""
    load_selfhosted_stdlib_source.cache_clear()