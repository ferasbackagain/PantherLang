#!/usr/bin/env bash
# PantherLang Example Runner — Linux / macOS
# Runs from repo root. Stop on first failure.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "========================================"
echo " PantherLang Example Runner"
echo "========================================"
echo ""

EXAMPLES=(
    "examples/console_hello/main.pan"
    "examples/calculator/calc.pan"
    "examples/hello_api/main.pan"
    "examples/hello_web/main.pan"
    "examples/hello_ai/main.pan"
    "examples/security_audit_demo/main.pan"
    "examples/file_manager/main.pan"
    "examples/sqlite_crud/main.pan"
    "examples/http_client/main.pan"
    "examples/json_parser/main.pan"
    "examples/config_loader/main.pan"
    # "examples/panther_neon_runner/main.pan"  # web server; requires browser interaction
)

for example in "${EXAMPLES[@]}"; do
    echo "--- Running: $example ---"
    if python3 -m cli.panther_cli run "$example"; then
        echo "--- PASS: $example ---"
    else
        echo "--- FAIL: $example ---"
        exit 1
    fi
    echo ""
done

echo "========================================"
echo " All examples passed!"
echo "========================================"
