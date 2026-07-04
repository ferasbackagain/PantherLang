#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLES="$ROOT/examples/conformance"
PASS=0
FAIL=0

echo "=========================================="
echo " PantherLang Conformance Test Runner"
echo "=========================================="

run_test() {
    local file="$1"
    local name="$(basename "$file")"
    echo ""
    echo "--- Running: $name ---"
    if python -m cli.panther_cli run "$file" 2>/dev/null; then
        echo "--- PASS: $name ---"
        PASS=$((PASS + 1))
    else
        echo "--- FAIL: $name ---"
        FAIL=$((FAIL + 1))
    fi
}

run_test "$EXAMPLES/01_literals.pan"
run_test "$EXAMPLES/02_variables.pan"
run_test "$EXAMPLES/03_assignment.pan"
run_test "$EXAMPLES/04_compound_assignment.pan"
run_test "$EXAMPLES/05_arrays_objects_indexing.pan"
run_test "$EXAMPLES/06_expressions_operators.pan"
run_test "$EXAMPLES/07_functions.pan"
run_test "$EXAMPLES/08_recursion.pan"
run_test "$EXAMPLES/09_control_flow.pan"
run_test "$EXAMPLES/10_loops.pan"
run_test "$EXAMPLES/11_structs.pan"
run_test "$EXAMPLES/12_stdlib_string_math_json.pan"
run_test "$EXAMPLES/13_filesystem.pan"
run_test "$EXAMPLES/14_sqlite_crud.pan"
run_test "$EXAMPLES/15_http_client.pan"
run_test "$EXAMPLES/16_security_audit.pan"
run_test "$EXAMPLES/17_ai_mock.pan"

echo ""
echo "=========================================="
echo " Results: $PASS passed, $FAIL failed"
echo "=========================================="
exit $FAIL
