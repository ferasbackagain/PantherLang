#!/usr/bin/env bash
set -euo pipefail

# PantherLang Developer Edition v0.5 -> Phase 6.8
# IDE & Language Server Protocol Bootstrap
# Target project root: ~/pantherlang/PantherLang_Developer_Edition_v0_5

ROOT="${PANTHERLANG_ROOT:-$HOME/pantherlang/PantherLang_Developer_Edition_v0_5}"
PHASE="6.8"
PHASE_NAME="IDE & Language Server Protocol"

log() { printf '\033[1;36m[PantherLang %s]\033[0m %s\n' "$PHASE" "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; exit 1; }

log "Starting Phase $PHASE bootstrap: $PHASE_NAME"

mkdir -p "$ROOT"
cd "$ROOT"

# -----------------------------------------------------------------------------
# Directory layout
# -----------------------------------------------------------------------------
mkdir -p \
  tools/panther-lsp \
  tools/panther-lsp/panther_lsp \
  tools/panther-lsp/tests \
  tools/panther-ide/vscode/pantherlang/syntaxes \
  tools/panther-ide/vscode/pantherlang/language-configuration \
  examples/phase_6_8_lsp \
  scripts \
  docs/phase_6 \
  .panther/phase_status

# -----------------------------------------------------------------------------
# Panther LSP package
# -----------------------------------------------------------------------------
cat > tools/panther-lsp/panther_lsp/__init__.py <<'PY'
"""PantherLang Language Server Protocol package."""

__version__ = "0.6.8"
PY

cat > tools/panther-lsp/panther_lsp/protocol.py <<'PY'
from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Any, Dict, Iterable, Optional


@dataclass
class JsonRpcMessage:
    """Minimal JSON-RPC 2.0 message wrapper used by the Panther LSP."""

    method: Optional[str]
    params: Dict[str, Any]
    id: Optional[Any] = None

    @staticmethod
    def parse(payload: str) -> "JsonRpcMessage":
        data = json.loads(payload)
        if data.get("jsonrpc") != "2.0":
            raise ValueError("Invalid JSON-RPC version")
        return JsonRpcMessage(method=data.get("method"), params=data.get("params") or {}, id=data.get("id"))


def make_response(message_id: Any, result: Any) -> Dict[str, Any]:
    return {"jsonrpc": "2.0", "id": message_id, "result": result}


def make_error(message_id: Any, code: int, message: str) -> Dict[str, Any]:
    return {"jsonrpc": "2.0", "id": message_id, "error": {"code": code, "message": message}}


def encode_lsp_payload(message: Dict[str, Any]) -> bytes:
    body = json.dumps(message, separators=(",", ":")).encode("utf-8")
    header = f"Content-Length: {len(body)}\r\n\r\n".encode("ascii")
    return header + body


def decode_lsp_stream(chunks: Iterable[bytes]) -> Iterable[Dict[str, Any]]:
    buffer = b""
    for chunk in chunks:
        buffer += chunk
        while True:
            marker = buffer.find(b"\r\n\r\n")
            if marker < 0:
                break
            header = buffer[:marker].decode("ascii", errors="replace")
            length = None
            for line in header.split("\r\n"):
                if line.lower().startswith("content-length:"):
                    length = int(line.split(":", 1)[1].strip())
                    break
            if length is None:
                raise ValueError("Missing Content-Length header")
            start = marker + 4
            end = start + length
            if len(buffer) < end:
                break
            body = buffer[start:end]
            buffer = buffer[end:]
            yield json.loads(body.decode("utf-8"))
PY

cat > tools/panther-lsp/panther_lsp/analyzer.py <<'PY'
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Dict, Iterable, List, Tuple

KEYWORDS = {
    "module", "import", "fn", "let", "mut", "return", "if", "else", "while", "for",
    "struct", "enum", "trait", "impl", "async", "await", "ai", "agent", "memory",
    "true", "false", "null",
}

BUILTINS = {
    "print": "fn print(value: any) -> void",
    "println": "fn println(value: any) -> void",
    "spawn": "fn spawn(task: async fn) -> Task",
    "panic": "fn panic(message: string) -> never",
}

TOKEN_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
FUNC_RE = re.compile(r"\bfn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)(?:\s*->\s*([A-Za-z_][A-Za-z0-9_<>]*))?")
LET_RE = re.compile(r"\blet\s+(?:mut\s+)?([A-Za-z_][A-Za-z0-9_]*)")
MODULE_RE = re.compile(r"\bmodule\s+([A-Za-z_][A-Za-z0-9_.]*)")
IMPORT_RE = re.compile(r"\bimport\s+([A-Za-z_][A-Za-z0-9_.]*)")


@dataclass
class Symbol:
    name: str
    kind: str
    line: int
    character: int
    detail: str


def _line_col(text: str, index: int) -> Tuple[int, int]:
    before = text[:index]
    line = before.count("\n")
    last = before.rfind("\n")
    character = index if last < 0 else index - last - 1
    return line, character


def analyze_symbols(text: str) -> List[Symbol]:
    symbols: List[Symbol] = []
    for match in MODULE_RE.finditer(text):
        line, char = _line_col(text, match.start(1))
        symbols.append(Symbol(match.group(1), "Module", line, char, "PantherLang module"))
    for match in IMPORT_RE.finditer(text):
        line, char = _line_col(text, match.start(1))
        symbols.append(Symbol(match.group(1), "Namespace", line, char, "Imported module"))
    for match in FUNC_RE.finditer(text):
        line, char = _line_col(text, match.start(1))
        ret = match.group(3) or "void"
        params = match.group(2).strip()
        symbols.append(Symbol(match.group(1), "Function", line, char, f"fn({params}) -> {ret}"))
    for match in LET_RE.finditer(text):
        line, char = _line_col(text, match.start(1))
        symbols.append(Symbol(match.group(1), "Variable", line, char, "local binding"))
    return symbols


def diagnostics(text: str) -> List[Dict]:
    result: List[Dict] = []
    stack: List[Tuple[str, int, int]] = []
    pairs = {"(": ")", "{": "}", "[": "]"}
    closing = {v: k for k, v in pairs.items()}

    for line_no, line in enumerate(text.splitlines()):
        stripped = line.strip()
        if stripped.startswith("fn ") and "{" not in stripped and not stripped.endswith(";"):
            result.append({
                "range": {"start": {"line": line_no, "character": 0}, "end": {"line": line_no, "character": len(line)}},
                "severity": 2,
                "source": "panther-lsp",
                "message": "Function declaration should open a block with '{' or end with ';'.",
            })
        for char_no, ch in enumerate(line):
            if ch in pairs:
                stack.append((ch, line_no, char_no))
            elif ch in closing:
                if not stack or stack[-1][0] != closing[ch]:
                    result.append({
                        "range": {"start": {"line": line_no, "character": char_no}, "end": {"line": line_no, "character": char_no + 1}},
                        "severity": 1,
                        "source": "panther-lsp",
                        "message": f"Unmatched closing '{ch}'.",
                    })
                else:
                    stack.pop()
    for opener, line_no, char_no in stack[-5:]:
        result.append({
            "range": {"start": {"line": line_no, "character": char_no}, "end": {"line": line_no, "character": char_no + 1}},
            "severity": 1,
            "source": "panther-lsp",
            "message": f"Unclosed '{opener}', expected '{pairs[opener]}'.",
        })
    return result


def completions(prefix: str = "") -> List[Dict]:
    items: List[Dict] = []
    for kw in sorted(KEYWORDS):
        if kw.startswith(prefix):
            items.append({"label": kw, "kind": 14, "detail": "PantherLang keyword"})
    for name, detail in sorted(BUILTINS.items()):
        if name.startswith(prefix):
            items.append({"label": name, "kind": 3, "detail": detail})
    return items


def hover(text: str, line: int, character: int) -> Dict:
    lines = text.splitlines()
    if line < 0 or line >= len(lines):
        return {"contents": ""}
    selected = lines[line]
    matches = list(TOKEN_RE.finditer(selected))
    token = ""
    for match in matches:
        if match.start() <= character <= match.end():
            token = match.group(0)
            break
    if not token:
        return {"contents": ""}
    if token in KEYWORDS:
        return {"contents": {"kind": "markdown", "value": f"`{token}` — PantherLang keyword."}}
    if token in BUILTINS:
        return {"contents": {"kind": "markdown", "value": f"`{BUILTINS[token]}`"}}
    for symbol in analyze_symbols(text):
        if symbol.name == token:
            return {"contents": {"kind": "markdown", "value": f"**{symbol.kind}** `{symbol.name}`\n\n{symbol.detail}"}}
    return {"contents": {"kind": "markdown", "value": f"`{token}`"}}


def document_symbols(text: str) -> List[Dict]:
    kind_map = {"File": 1, "Module": 2, "Namespace": 3, "Function": 12, "Variable": 13}
    return [
        {
            "name": symbol.name,
            "kind": kind_map.get(symbol.kind, 13),
            "detail": symbol.detail,
            "range": {
                "start": {"line": symbol.line, "character": symbol.character},
                "end": {"line": symbol.line, "character": symbol.character + len(symbol.name)},
            },
            "selectionRange": {
                "start": {"line": symbol.line, "character": symbol.character},
                "end": {"line": symbol.line, "character": symbol.character + len(symbol.name)},
            },
        }
        for symbol in analyze_symbols(text)
    ]
PY

cat > tools/panther-lsp/panther_lsp/server.py <<'PY'
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict

from .analyzer import completions, diagnostics, document_symbols, hover
from .protocol import encode_lsp_payload, make_error, make_response

CAPABILITIES = {
    "textDocumentSync": 1,
    "completionProvider": {"resolveProvider": False, "triggerCharacters": [".", ":"]},
    "hoverProvider": True,
    "documentSymbolProvider": True,
    "diagnosticProvider": {"identifier": "panther-lsp", "interFileDependencies": False, "workspaceDiagnostics": False},
}


class PantherLanguageServer:
    def __init__(self) -> None:
        self.documents: Dict[str, str] = {}

    def handle(self, message: Dict[str, Any]) -> Dict[str, Any] | None:
        method = message.get("method")
        msg_id = message.get("id")
        params = message.get("params") or {}

        if method == "initialize":
            return make_response(msg_id, {"capabilities": CAPABILITIES, "serverInfo": {"name": "panther-lsp", "version": "0.6.8"}})
        if method == "shutdown":
            return make_response(msg_id, None)
        if method == "textDocument/didOpen":
            doc = params.get("textDocument", {})
            self.documents[doc.get("uri", "")] = doc.get("text", "")
            return None
        if method == "textDocument/didChange":
            doc = params.get("textDocument", {})
            changes = params.get("contentChanges", [])
            if changes:
                self.documents[doc.get("uri", "")] = changes[-1].get("text", "")
            return None
        if method == "textDocument/completion":
            return make_response(msg_id, {"isIncomplete": False, "items": completions()})
        if method == "textDocument/hover":
            uri = params.get("textDocument", {}).get("uri", "")
            pos = params.get("position", {})
            return make_response(msg_id, hover(self.documents.get(uri, ""), int(pos.get("line", 0)), int(pos.get("character", 0))))
        if method == "textDocument/documentSymbol":
            uri = params.get("textDocument", {}).get("uri", "")
            return make_response(msg_id, document_symbols(self.documents.get(uri, "")))
        if method == "textDocument/diagnostic":
            uri = params.get("textDocument", {}).get("uri", "")
            return make_response(msg_id, {"kind": "full", "items": diagnostics(self.documents.get(uri, ""))})
        return make_error(msg_id, -32601, f"Method not found: {method}")


def stdio_loop() -> int:
    server = PantherLanguageServer()
    while True:
        header = sys.stdin.buffer.readline()
        if not header:
            return 0
        if not header.lower().startswith(b"content-length:"):
            continue
        length = int(header.decode("ascii").split(":", 1)[1].strip())
        sys.stdin.buffer.readline()
        payload = sys.stdin.buffer.read(length)
        message = json.loads(payload.decode("utf-8"))
        response = server.handle(message)
        if response is not None:
            sys.stdout.buffer.write(encode_lsp_payload(response))
            sys.stdout.buffer.flush()


def analyze_file(path: Path) -> int:
    text = path.read_text(encoding="utf-8")
    print(json.dumps({
        "file": str(path),
        "diagnostics": diagnostics(text),
        "symbols": document_symbols(text),
        "completions": completions(),
    }, indent=2))
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="PantherLang Language Server")
    parser.add_argument("--stdio", action="store_true", help="Run as JSON-RPC/LSP stdio server")
    parser.add_argument("--analyze", type=Path, help="Analyze a PantherLang source file and print JSON")
    args = parser.parse_args(argv)

    if args.analyze:
        return analyze_file(args.analyze)
    if args.stdio:
        return stdio_loop()
    parser.print_help()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY

cat > tools/panther-lsp/pyproject.toml <<'PYPROJECT'
[project]
name = "panther-lsp"
version = "0.6.8"
description = "PantherLang Language Server Protocol implementation"
requires-python = ">=3.10"
authors = [{ name = "PantherLang Core Team" }]

[project.scripts]
panther-lsp = "panther_lsp.server:main"

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["."]
PYPROJECT

cat > tools/panther-lsp/tests/test_lsp_core.py <<'PY'
from panther_lsp.analyzer import completions, diagnostics, document_symbols, hover
from panther_lsp.server import PantherLanguageServer

SAMPLE = """module demo.phase68
import std.io

fn main() -> int {
    let answer = 42
    println(answer)
    return answer
}
"""


def test_symbols_include_module_function_and_variable():
    names = [item["name"] for item in document_symbols(SAMPLE)]
    assert "demo.phase68" in names
    assert "main" in names
    assert "answer" in names


def test_completions_include_ai_and_async_language_terms():
    labels = [item["label"] for item in completions()]
    assert "async" in labels
    assert "agent" in labels
    assert "println" in labels


def test_diagnostics_detect_unclosed_block():
    bad = "fn broken() -> int {\n let x = 1\n"
    messages = [item["message"] for item in diagnostics(bad)]
    assert any("Unclosed" in msg for msg in messages)


def test_hover_returns_symbol_details():
    result = hover(SAMPLE, 3, 3)
    assert "main" in result["contents"]["value"]


def test_server_initialize_and_document_symbols():
    server = PantherLanguageServer()
    init = server.handle({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}})
    assert init["result"]["serverInfo"]["version"] == "0.6.8"
    uri = "file:///demo.panther"
    server.handle({"jsonrpc": "2.0", "method": "textDocument/didOpen", "params": {"textDocument": {"uri": uri, "text": SAMPLE}}})
    response = server.handle({"jsonrpc": "2.0", "id": 2, "method": "textDocument/documentSymbol", "params": {"textDocument": {"uri": uri}}})
    assert any(item["name"] == "main" for item in response["result"])
PY

# -----------------------------------------------------------------------------
# VS Code extension scaffold
# -----------------------------------------------------------------------------
cat > tools/panther-ide/vscode/pantherlang/package.json <<'JSON'
{
  "name": "pantherlang",
  "displayName": "PantherLang",
  "description": "IDE support for PantherLang with syntax highlighting and LSP integration.",
  "version": "0.6.8",
  "publisher": "pantherlang",
  "engines": { "vscode": "^1.85.0" },
  "categories": ["Programming Languages"],
  "activationEvents": ["onLanguage:pantherlang"],
  "main": "./extension.js",
  "contributes": {
    "languages": [
      {
        "id": "pantherlang",
        "aliases": ["PantherLang", "panther"],
        "extensions": [".panther", ".pn"],
        "configuration": "./language-configuration/language-configuration.json"
      }
    ],
    "grammars": [
      {
        "language": "pantherlang",
        "scopeName": "source.pantherlang",
        "path": "./syntaxes/pantherlang.tmLanguage.json"
      }
    ],
    "configuration": {
      "title": "PantherLang",
      "properties": {
        "pantherlang.lsp.path": {
          "type": "string",
          "default": "panther-lsp",
          "description": "Path to the PantherLang language server executable."
        }
      }
    }
  }
}
JSON

cat > tools/panther-ide/vscode/pantherlang/extension.js <<'JS'
const vscode = require('vscode');
const cp = require('child_process');

let clientProcess = null;

function activate(context) {
  const output = vscode.window.createOutputChannel('PantherLang');
  context.subscriptions.push(output);

  const disposable = vscode.commands.registerCommand('pantherlang.restartLsp', () => {
    if (clientProcess) {
      clientProcess.kill();
      clientProcess = null;
    }
    vscode.window.showInformationMessage('PantherLang LSP restart requested.');
  });
  context.subscriptions.push(disposable);

  output.appendLine('PantherLang IDE extension activated. Configure pantherlang.lsp.path if needed.');
}

function deactivate() {
  if (clientProcess) {
    clientProcess.kill();
    clientProcess = null;
  }
}

module.exports = { activate, deactivate };
JS

cat > tools/panther-ide/vscode/pantherlang/language-configuration/language-configuration.json <<'JSON'
{
  "comments": {
    "lineComment": "//",
    "blockComment": ["/*", "*/"]
  },
  "brackets": [["{", "}"], ["[", "]"], ["(", ")"]],
  "autoClosingPairs": [
    { "open": "{", "close": "}" },
    { "open": "[", "close": "]" },
    { "open": "(", "close": ")" },
    { "open": "\"", "close": "\"" }
  ],
  "surroundingPairs": [
    ["{", "}"], ["[", "]"], ["(", ")"], ["\"", "\""]
  ]
}
JSON

cat > tools/panther-ide/vscode/pantherlang/syntaxes/pantherlang.tmLanguage.json <<'JSON'
{
  "$schema": "https://raw.githubusercontent.com/martinring/tmlanguage/master/tmlanguage.json",
  "name": "PantherLang",
  "scopeName": "source.pantherlang",
  "patterns": [
    { "include": "#comments" },
    { "include": "#strings" },
    { "include": "#keywords" },
    { "include": "#functions" },
    { "include": "#numbers" }
  ],
  "repository": {
    "comments": {
      "patterns": [
        { "name": "comment.line.double-slash.pantherlang", "match": "//.*$" },
        { "name": "comment.block.pantherlang", "begin": "/\\*", "end": "\\*/" }
      ]
    },
    "strings": {
      "patterns": [
        { "name": "string.quoted.double.pantherlang", "begin": "\"", "end": "\"", "patterns": [{ "name": "constant.character.escape.pantherlang", "match": "\\\\." }] }
      ]
    },
    "keywords": {
      "patterns": [
        { "name": "keyword.control.pantherlang", "match": "\\b(if|else|while|for|return|async|await)\\b" },
        { "name": "keyword.declaration.pantherlang", "match": "\\b(module|import|fn|let|mut|struct|enum|trait|impl|ai|agent|memory)\\b" },
        { "name": "constant.language.pantherlang", "match": "\\b(true|false|null)\\b" }
      ]
    },
    "functions": {
      "patterns": [
        { "name": "entity.name.function.pantherlang", "match": "(?<=\\bfn\\s)[A-Za-z_][A-Za-z0-9_]*" }
      ]
    },
    "numbers": {
      "patterns": [
        { "name": "constant.numeric.pantherlang", "match": "\\b[0-9]+(?:\\.[0-9]+)?\\b" }
      ]
    }
  }
}
JSON

# -----------------------------------------------------------------------------
# Example source
# -----------------------------------------------------------------------------
cat > examples/phase_6_8_lsp/hello_lsp.panther <<'PANTHER'
module examples.phase_6_8_lsp
import std.io

fn main() -> int {
    let message = "PantherLang Phase 6.8 LSP is active"
    println(message)
    return 0
}
PANTHER

# -----------------------------------------------------------------------------
# Verification script
# -----------------------------------------------------------------------------
cat > scripts/verify_phase_6_8_ide_lsp.sh <<'VERIFY'
#!/usr/bin/env bash
set -euo pipefail

ROOT="${PANTHERLANG_ROOT:-$HOME/pantherlang/PantherLang_Developer_Edition_v0_5}"
cd "$ROOT"

printf '\n[verify 6.8] Checking required files...\n'
required=(
  "tools/panther-lsp/panther_lsp/server.py"
  "tools/panther-lsp/panther_lsp/analyzer.py"
  "tools/panther-lsp/panther_lsp/protocol.py"
  "tools/panther-lsp/tests/test_lsp_core.py"
  "tools/panther-ide/vscode/pantherlang/package.json"
  "tools/panther-ide/vscode/pantherlang/syntaxes/pantherlang.tmLanguage.json"
  "examples/phase_6_8_lsp/hello_lsp.panther"
  "docs/phase_6/PHASE_6_8_IDE_LSP.md"
)
for path in "${required[@]}"; do
  [[ -f "$path" ]] || { echo "Missing: $path" >&2; exit 1; }
  echo "OK: $path"
done

printf '\n[verify 6.8] Running Python unit tests...\n'
PYTHONPATH="tools/panther-lsp" python3 -m unittest discover -s tools/panther-lsp/tests -p 'test_*.py' -v

printf '\n[verify 6.8] Running analyzer smoke test...\n'
PYTHONPATH="tools/panther-lsp" python3 -m panther_lsp.server --analyze examples/phase_6_8_lsp/hello_lsp.panther > /tmp/panther_phase_6_8_lsp_analysis.json
python3 - <<'PY'
import json
from pathlib import Path
report = json.loads(Path('/tmp/panther_phase_6_8_lsp_analysis.json').read_text())
assert any(s['name'] == 'main' for s in report['symbols']), 'main symbol missing'
assert any(c['label'] == 'println' for c in report['completions']), 'println completion missing'
assert report['file'].endswith('hello_lsp.panther')
print('Analyzer JSON validated:', report['file'])
PY

printf '\n[verify 6.8] Running protocol encode/decode smoke test...\n'
PYTHONPATH="tools/panther-lsp" python3 - <<'PY'
from panther_lsp.protocol import encode_lsp_payload, decode_lsp_stream
payload = encode_lsp_payload({'jsonrpc':'2.0','id':99,'result':{'ok':True}})
messages = list(decode_lsp_stream([payload]))
assert messages[0]['id'] == 99 and messages[0]['result']['ok'] is True
print('Protocol framing validated')
PY

printf '\n[verify 6.8] Phase 6.8 verification PASSED.\n'
VERIFY
chmod +x scripts/verify_phase_6_8_ide_lsp.sh

# -----------------------------------------------------------------------------
# Documentation and status
# -----------------------------------------------------------------------------
cat > docs/phase_6/PHASE_6_8_IDE_LSP.md <<'MD'
# PantherLang Phase 6.8 — IDE & Language Server Protocol

## Status
Implemented bootstrap scaffold for PantherLang IDE support and a minimal Language Server Protocol implementation.

## Added Components

- `tools/panther-lsp/`
  - JSON-RPC/LSP protocol framing
  - PantherLang analyzer for symbols, diagnostics, hover, and completions
  - stdio language server entry point
  - unit tests

- `tools/panther-ide/vscode/pantherlang/`
  - VS Code language extension scaffold
  - `.panther` and `.pn` language registration
  - syntax highlighting grammar
  - bracket/comment/auto-closing configuration

- `examples/phase_6_8_lsp/hello_lsp.panther`
  - Practical PantherLang source file for LSP analyzer testing

- `scripts/verify_phase_6_8_ide_lsp.sh`
  - Required-file validation
  - Python unit tests
  - Analyzer smoke test
  - JSON-RPC protocol framing test

## LSP Capabilities

- `initialize`
- `shutdown`
- `textDocument/didOpen`
- `textDocument/didChange`
- `textDocument/completion`
- `textDocument/hover`
- `textDocument/documentSymbol`
- `textDocument/diagnostic`

## Verification

Run:

```bash
cd ~/pantherlang/PantherLang_Developer_Edition_v0_5
bash scripts/verify_phase_6_8_ide_lsp.sh
```

Expected result:

```text
Phase 6.8 verification PASSED.
```

## Next Phase

Phase 6.9 — Cross Platform Toolchain.
MD

cat > .panther/phase_status/phase_6_8_ide_lsp.json <<'JSON'
{
  "phase": "6.8",
  "name": "IDE & Language Server Protocol",
  "status": "bootstrapped",
  "components": [
    "panther-lsp",
    "vscode-extension-scaffold",
    "syntax-highlighting",
    "document-symbols",
    "hover",
    "completion",
    "diagnostics",
    "verification-script"
  ],
  "next_phase": "6.9 Cross Platform Toolchain"
}
JSON

log "Running Phase 6.8 verification..."
bash scripts/verify_phase_6_8_ide_lsp.sh

log "Phase 6.8 bootstrap completed successfully."
log "Next: Phase 6.9 — Cross Platform Toolchain"
