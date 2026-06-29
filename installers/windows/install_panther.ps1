$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$InstallDir = Join-Path $env:USERPROFILE ".pantherlang\bin"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

$CmdPath = Join-Path $InstallDir "Panther.cmd"
@"
@echo off
python "$Root\panther" %*
"@ | Set-Content -Encoding ASCII $CmdPath

Write-Host "Panther installed to $CmdPath"
Write-Host "Add $InstallDir to PATH if it is not already available."
