$ROOT = Split-Path -Parent $PSScriptRoot
$EXAMPLES = Join-Path $ROOT "examples\conformance"
$PASS = 0
$FAIL = 0

Write-Host "=========================================="
Write-Host " PantherLang Conformance Test Runner"
Write-Host "=========================================="

function Run-Test {
    param($File)
    $Name = Split-Path $File -Leaf
    Write-Host ""
    Write-Host "--- Running: $Name ---"
    $result = & python -m cli.panther_cli run $File 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "--- PASS: $Name ---"
        $script:PASS++
    } else {
        Write-Host "--- FAIL: $Name ---"
        $script:FAIL++
    }
}

Run-Test (Join-Path $EXAMPLES "01_literals.pan")
Run-Test (Join-Path $EXAMPLES "02_variables.pan")
Run-Test (Join-Path $EXAMPLES "03_assignment.pan")
Run-Test (Join-Path $EXAMPLES "04_compound_assignment.pan")
Run-Test (Join-Path $EXAMPLES "05_arrays_objects_indexing.pan")
Run-Test (Join-Path $EXAMPLES "06_expressions_operators.pan")
Run-Test (Join-Path $EXAMPLES "07_functions.pan")
Run-Test (Join-Path $EXAMPLES "08_recursion.pan")
Run-Test (Join-Path $EXAMPLES "09_control_flow.pan")
Run-Test (Join-Path $EXAMPLES "10_loops.pan")
Run-Test (Join-Path $EXAMPLES "11_structs.pan")
Run-Test (Join-Path $EXAMPLES "12_stdlib_string_math_json.pan")
Run-Test (Join-Path $EXAMPLES "13_filesystem.pan")
Run-Test (Join-Path $EXAMPLES "14_sqlite_crud.pan")
Run-Test (Join-Path $EXAMPLES "15_http_client.pan")
Run-Test (Join-Path $EXAMPLES "16_security_audit.pan")
Run-Test (Join-Path $EXAMPLES "17_ai_mock.pan")

Write-Host ""
Write-Host "=========================================="
Write-Host " Results: $PASS passed, $FAIL failed"
Write-Host "=========================================="
exit $FAIL
