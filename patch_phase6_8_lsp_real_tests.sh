#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(pwd)"
PHASE="6.8"
LOG_PREFIX="[PantherLang ${PHASE} Test Patch]"

printf '%s Applying real LSP tests patch...\n' "$LOG_PREFIX"

mkdir -p tools/panther-lsp/tests scripts build/reports

cat > tools/panther-lsp/tests/test_lsp_core.py <<'PY'
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
PY

cat > verify_phase6_8_ide_lsp.sh <<'BASH'
#!/usr/bin/env bash
set -Eeuo pipefail

PHASE="6.8"
REPORT_DIR="build/reports"
REPORT="$REPORT_DIR/phase6_8_lsp_real_tests_report.json"
mkdir -p "$REPORT_DIR"

printf '[verify 6.8] Checking required files ...\n'
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

for file in "${required[@]}"; do
  if [[ ! -f "$file" ]]; then
    printf 'FAIL: missing %s\n' "$file"
    exit 1
  fi
  printf 'OK: %s\n' "$file"
done

printf '\n[verify 6.8] Running Python unit tests ...\n'
set +e
TEST_OUTPUT=$(python3 -m unittest discover -s tools/panther-lsp/tests -p 'test_*.py' -v 2>&1)
TEST_STATUS=$?
set -e
printf '%s\n' "$TEST_OUTPUT"

if printf '%s\n' "$TEST_OUTPUT" | grep -q "Ran 0 tests"; then
  printf '\nFAIL: unittest discovered zero tests.\n'
  exit 1
fi

if [[ $TEST_STATUS -ne 0 ]]; then
  printf '\nFAIL: Phase 6.8 unit tests failed.\n'
  exit "$TEST_STATUS"
fi

TEST_COUNT=$(printf '%s\n' "$TEST_OUTPUT" | sed -nE 's/^Ran ([0-9]+) tests?.*/\1/p' | tail -n 1)
if [[ -z "${TEST_COUNT:-}" || "$TEST_COUNT" -lt 1 ]]; then
  printf '\nFAIL: Could not confirm executed test count.\n'
  exit 1
fi

python3 - <<PY
import json
from pathlib import Path
report = {
    "phase": "6.8",
    "name": "IDE & Language Server Protocol",
    "status": "PASS",
    "test_count": int("$TEST_COUNT"),
    "zero_test_guard": "ENABLED",
    "report": "$REPORT",
}
Path("$REPORT").write_text(json.dumps(report, indent=2), encoding="utf-8")
print(f"Report written: {$REPORT!r}")
PY

printf '\nPhase 6.8 real LSP verification completed successfully.\n'
BASH
chmod +x verify_phase6_8_ide_lsp.sh

# Also keep scripts/ path compatible if project expects it.
cp verify_phase6_8_ide_lsp.sh scripts/verify_phase_6_8_ide_lsp.sh
chmod +x scripts/verify_phase_6_8_ide_lsp.sh

printf '%s Patch complete. Run:\n' "$LOG_PREFIX"
printf 'bash verify_phase6_8_ide_lsp.sh\n'
