$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)
panther run examples/stdlib_s1_s6_contract/main.pan
