# PantherLang Installer — Windows PowerShell
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File install.ps1
#

$ErrorActionPreference = "Stop"
$InstallDir = Join-Path $env:USERPROFILE ".pantherlang\bin"

Write-Host "PantherLang Installer" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

# Check Python
try {
    $pyVersion = & python3 --version 2>&1
    Write-Host "Python: $pyVersion"
} catch {
    try {
        $pyVersion = & python --version 2>&1
        Write-Host "Python: $pyVersion"
    } catch {
        Write-Host "ERROR: Python 3.10+ is required but not found." -ForegroundColor Red
        exit 1
    }
}

# Install via pip
Write-Host ""
Write-Host "Installing pantherlang..."
try {
    & pip install --upgrade pantherlang 2>&1
} catch {
    Write-Host "Installing from local source..."
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Push-Location $ScriptDir
    try {
        & pip install -e . 2>&1
    } finally {
        Pop-Location
    }
}

# Create PATH helper
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$CmdPath = Join-Path $InstallDir "panther.cmd"
@"
@echo off
python -m cli.panther_cli %*
"@ | Set-Content -Encoding ASCII $CmdPath

Write-Host ""
Write-Host "PantherLang installed!" -ForegroundColor Green
Write-Host ""
Write-Host "Add to your PATH:"
Write-Host "  [Environment]::SetEnvironmentVariable('PATH', '$InstallDir;' + `$env:PATH, 'User')"
Write-Host ""
Write-Host "Or run: panther doctor"
