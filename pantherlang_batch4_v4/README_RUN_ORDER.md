# PantherLang R3 Batch 4 v4 — Debug Adapter ReferenceEntry Repair

## Goal
Fix the current regression collection blocker:

```text
ImportError: cannot import name 'ReferenceEntry' from debug_adapter.variable_references
```

This bundle is focused on Debug Adapter compatibility before Expression Parser work resumes.

## Run

From Kali:

```bash
cd ~/Downloads
unzip pantherlang_R3_batch4_v4_debug_adapter_referenceentry_repair.zip -d pantherlang_R3_batch4_v4

cd /home/panther/pantherlang/PantherLang_Developer_Edition_v0_5
bash ~/Downloads/pantherlang_R3_batch4_v4/pantherlang_batch4_v4/scripts/bootstrap_00_R3_batch4_v4_debug_adapter_referenceentry_repair.sh
```

## First targeted proof

```bash
python3 -m pytest -q \
  tests/H4_1/test_debug_adapter_core.py \
  tests/P3_atomic_replacement/test_p3_batch6_production_debug_adapter.py \
  tests/test_h4_3_d2_variables_references.py \
  tests/test_h4_3_d3_variable_store.py \
  tests/test_h4_3_d7_evaluate.py
```

Expected targeted result from my local extracted test subset:

```text
29 passed
```

## Then full regression

```bash
python3 -m pytest -q
```

Send the full output back. If the full run exposes the next compatibility layer, we continue with Batch 4 v5.
