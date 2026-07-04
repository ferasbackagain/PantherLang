# PantherLang Example Runner — Windows PowerShell
# Runs from repo root. Stop on first failure.
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " PantherLang Example Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$Examples = @(
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
)

foreach ($example in $Examples) {
    Write-Host "--- Running: $example ---" -ForegroundColor Yellow
    $exitCode = 0
    try {
        python -m cli.panther_cli run $example
        $exitCode = $LASTEXITCODE
    } catch {
        $exitCode = 1
    }
    if ($exitCode -eq 0) {
        Write-Host "--- PASS: $example ---" -ForegroundColor Green
    } else {
        Write-Host "--- FAIL: $example ---" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " All examples passed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
