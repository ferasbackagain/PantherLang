import json
import os
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
LSP_ROOT = ROOT / "tools" / "panther-lsp"
sys.path.insert(0, str(LSP_ROOT))

from panther_lsp.protocol import make_response, make_notification, parse_message
from panther_lsp.analyzer import analyze_source, collect_symbols
from panther_lsp.server import PantherLSPServer


class TestPantherLSPProtocol(unittest.TestCase):
    def test_make_response_shape(self):
        response = make_response(7, {"ok": True})
        self.assertEqual(response["jsonrpc"], "2.0")
        self.assertEqual(response["id"], 7)
        self.assertEqual(response["result"], {"ok": True})

    def test_make_notification_shape(self):
        notification = make_notification("textDocument/publishDiagnostics", {"uri": "file:///x.panther"})
        self.assertEqual(notification["jsonrpc"], "2.0")
        self.assertEqual(notification["method"], "textDocument/publishDiagnostics")
        self.assertIn("params", notification)

    def test_parse_message_valid_json(self):
        message = parse_message('{"jsonrpc":"2.0","id":1,"method":"initialize"}')
        self.assertEqual(message["method"], "initialize")
        self.assertEqual(message["id"], 1)


class TestPantherLSPAnalyzer(unittest.TestCase):
    def test_collect_symbols_detects_function(self):
        source = "fn hello(name: String) -> String {\n  return name\n}\n"
        symbols = collect_symbols(source)
        names = [symbol.get("name") for symbol in symbols]
        self.assertIn("hello", names)

    def test_analyze_source_returns_diagnostics_list(self):
        result = analyze_source("fn main() {\n  let x = 1\n}\n")
        self.assertIn("diagnostics", result)
        self.assertIsInstance(result["diagnostics"], list)

    def test_analyze_source_reports_unbalanced_braces(self):
        result = analyze_source("fn broken() {\n  let x = 1\n")
        diagnostics = result.get("diagnostics", [])
        self.assertTrue(any("brace" in d.get("message", "").lower() for d in diagnostics))


class TestPantherLSPServer(unittest.TestCase):
    def test_server_initialization_capabilities(self):
        server = PantherLSPServer()
        response = server.handle({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}})
        self.assertEqual(response["id"], 1)
        self.assertIn("capabilities", response["result"])
        self.assertTrue(response["result"]["capabilities"].get("textDocumentSync"))

    def test_server_shutdown(self):
        server = PantherLSPServer()
        response = server.handle({"jsonrpc": "2.0", "id": 2, "method": "shutdown", "params": {}})
        self.assertEqual(response["result"], None)


if __name__ == "__main__":
    unittest.main(verbosity=2)
