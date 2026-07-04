@echo off
setlocal enabledelayedexpansion
set ROOT=%~dp0..
set EXAMPLES=%ROOT%\examples\conformance
set PASS=0
set FAIL=0

echo ==========================================
echo  PantherLang Conformance Test Runner
echo ==========================================

for %%f in (
    "01_literals.pan" "02_variables.pan" "03_assignment.pan"
    "04_compound_assignment.pan" "05_arrays_objects_indexing.pan"
    "06_expressions_operators.pan" "07_functions.pan"
    "08_recursion.pan" "09_control_flow.pan" "10_loops.pan"
    "11_structs.pan" "12_stdlib_string_math_json.pan"
    "13_filesystem.pan" "14_sqlite_crud.pan"
    "15_http_client.pan" "16_security_audit.pan"
    "17_ai_mock.pan"
) do (
    echo.
    echo --- Running: %%f ---
    python -m cli.panther_cli run "%EXAMPLES%\%%f" >nul 2>&1
    if !errorlevel! equ 0 (
        echo --- PASS: %%f ---
        set /a PASS+=1
    ) else (
        echo --- FAIL: %%f ---
        set /a FAIL+=1
    )
)

echo.
echo ==========================================
echo  Results: %PASS% passed, %FAIL% failed
echo ==========================================
exit /b %FAIL%
