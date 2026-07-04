@echo off
REM PantherLang Example Runner — Windows CMD
REM Runs from repo root. Stop on first failure.

setlocal enabledelayedexpansion
pushd %~dp0\..

echo ========================================
echo  PantherLang Example Runner
echo ========================================
echo.

set EXAMPLES=^
examples/console_hello/main.pan ^
examples/calculator/calc.pan ^
examples/hello_api/main.pan ^
examples/hello_web/main.pan ^
examples/hello_ai/main.pan ^
examples/security_audit_demo/main.pan ^
examples/file_manager/main.pan ^
examples/sqlite_crud/main.pan ^
examples/http_client/main.pan ^
examples/json_parser/main.pan ^
examples/config_loader/main.pan

for %%f in (%EXAMPLES%) do (
    echo --- Running: %%f ---
    python -m cli.panther_cli run "%%f"
    if errorlevel 1 (
        echo --- FAIL: %%f ---
        exit /b 1
    )
    echo --- PASS: %%f ---
    echo.
)

echo ========================================
echo  All examples passed!
echo ========================================
popd
