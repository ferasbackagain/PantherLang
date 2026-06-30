#!/usr/bin/env bash
set -Eeuo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -d "debug_adapter" || ! -d "compiler" ]]; then
  echo "ERROR: Run this from PantherLang repository root."
  exit 1
fi
bash "$HERE/bootstrap_00_R3_batch4_v3_debug_adapter_compatibility_repair.sh"
python3 -m pytest -q || { echo "Full regression still has failures. Send output before running step 01."; exit 2; }
bash "$HERE/bootstrap_01_R3_batch2_part3_3_expression_parser_reference_app_foundation.sh"
python3 -m pytest -q
