def collect_symbols(source):
    symbols = []
    for line_no, line in enumerate(source.splitlines()):
        stripped = line.strip()
        if not stripped or stripped.startswith("//") or stripped.startswith("#"):
            continue
        parts = stripped.replace("(", " ").replace("{", " ").replace(":", " ").split()
        if not parts:
            continue
        kind = None
        name = None
        if parts[0] in {"fn", "function"} and len(parts) >= 2:
            kind = "function"
            name = parts[1]
        elif parts[0] in {"let", "var", "const"} and len(parts) >= 2:
            kind = "variable"
            name = parts[1].rstrip("=")
        elif parts[0] in {"class", "struct", "module"} and len(parts) >= 2:
            kind = parts[0]
            name = parts[1]
        if kind and name:
            symbols.append({"name": name, "kind": kind, "line": line_no, "character": line.find(name)})
    return symbols

def analyze_source(source):
    diagnostics = []
    symbols = collect_symbols(source)
    for line_no, line in enumerate(source.splitlines()):
        stripped = line.strip()
        if stripped.count("{") != stripped.count("}"):
            diagnostics.append({"line": line_no, "character": 0, "severity": "error", "message": "Unbalanced braces"})
        if stripped.count("(") != stripped.count(")"):
            diagnostics.append({"line": line_no, "character": 0, "severity": "error", "message": "Unbalanced parentheses"})
        if stripped.startswith("let ") and "=" not in stripped:
            diagnostics.append({"line": line_no, "character": 0, "severity": "warning", "message": "Variable declaration missing assignment"})
    return {"diagnostics": diagnostics, "symbols": symbols}

def diagnostics(source):
    return analyze_source(source)["diagnostics"]

def document_symbols(source):
    return collect_symbols(source)

def hover(source, line, character):
    for s in collect_symbols(source):
        if s["line"] == line:
            return {"contents": f"PantherLang {s['kind']}: {s['name']}"}
    return {"contents": "PantherLang symbol information"}

def completions(source="", line=0, character=0):
    return [
        {"label": "fn", "kind": 14},
        {"label": "let", "kind": 14},
        {"label": "module", "kind": 14},
        {"label": "struct", "kind": 14},
        {"label": "return", "kind": 14},
    ]
