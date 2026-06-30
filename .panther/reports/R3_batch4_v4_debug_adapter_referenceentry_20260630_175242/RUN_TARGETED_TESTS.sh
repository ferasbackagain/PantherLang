#!/usr/bin/env bash
set -euo pipefail
python3 -m pytest -q \
  tests/H4_1/test_debug_adapter_core.py \
  tests/P3_atomic_replacement/test_p3_batch6_production_debug_adapter.py \
  tests/test_h4_3_d2_variables_references.py \
  tests/test_h4_3_d3_variable_store.py \
  tests/test_h4_3_d7_evaluate.py
