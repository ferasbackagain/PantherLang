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

class PantherLSPServer:
    def __init__(self):
        self.documents = {}
        self.initialized = False

    def initialize(self, root_uri=None):
        self.initialized = True
        return {
            "capabilities": {
                "textDocumentSync": 1,
                "hoverProvider": True,
                "completionProvider": {"resolveProvider": False},
                "documentSymbolProvider": True
            },
            "serverInfo": {"name": "PantherLang LSP", "version": "6.8"}
        }

    def did_open(self, uri, text, language_id="panther"):
        self.documents[uri] = {"uri": uri, "languageId": language_id, "text": text}
        from panther_lsp.analyzer import analyze_source
        return analyze_source(text)

    def did_change(self, uri, text):
        self.documents[uri] = {"uri": uri, "languageId": "panther", "text": text}
        from panther_lsp.analyzer import analyze_source
        return analyze_source(text)

    def hover(self, uri, line, character):
        return {"contents": "PantherLang symbol information"}

    def completion(self, uri, line, character):
        return {
            "isIncomplete": False,
            "items": [
                {"label": "fn", "kind": 14},
                {"label": "let", "kind": 14},
                {"label": "module", "kind": 14},
                {"label": "return", "kind": 14}
            ]
        }

    def document_symbols(self, uri):
        from panther_lsp.analyzer import collect_symbols
        source = self.documents.get(uri, {}).get("text", "")
        return [
            {
                "name": s["name"],
                "kind": 12,
                "range": {
                    "start": {"line": s["line"], "character": s["character"]},
                    "end": {"line": s["line"], "character": s["character"] + len(s["name"])}
                },
                "selectionRange": {
                    "start": {"line": s["line"], "character": s["character"]},
                    "end": {"line": s["line"], "character": s["character"] + len(s["name"])}
                }
            }
            for s in collect_symbols(source)
        ]


def _panther_lsp_handle(self, message):
    method = message.get("method")
    msg_id = message.get("id")
    params = message.get("params") or {}

    if method == "initialize":
        result = self.initialize(params.get("rootUri"))
        return {"jsonrpc": "2.0", "id": msg_id, "result": result}

    if method == "shutdown":
        return {"jsonrpc": "2.0", "id": msg_id, "result": None}

    return {
        "jsonrpc": "2.0",
        "id": msg_id,
        "error": {"code": -32601, "message": f"Method not found: {method}"},
    }

PantherLSPServer.handle = _panther_lsp_handle
