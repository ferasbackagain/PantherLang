# PantherLang All-in-One Bundle Run Order

## 1. Extract

```bash
cd ~/Downloads
unzip pantherlang_all_in_one_reference_bundle.zip -d pantherlang_all_in_one_reference_bundle
```

## 2. Run Debug Adapter repair first

```bash
cd /home/panther/pantherlang/PantherLang_Developer_Edition_v0_5
bash ~/Downloads/pantherlang_all_in_one_reference_bundle/scripts/bootstrap_00_R3_batch4_v3_debug_adapter_compatibility_repair.sh
python3 -m pytest -q
```

Send the full pytest output after this step.

## 3. Run Expression Parser only after Debug Adapter collection errors are resolved

```bash
cd /home/panther/pantherlang/PantherLang_Developer_Edition_v0_5
bash ~/Downloads/pantherlang_all_in_one_reference_bundle/scripts/bootstrap_01_R3_batch2_part3_3_expression_parser_reference_app_foundation.sh
python3 -m pytest -q
```
