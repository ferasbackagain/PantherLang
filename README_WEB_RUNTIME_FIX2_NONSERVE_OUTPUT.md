# Web Runtime Fix 2 — Non-Serve Output Compatibility

Apply from the PantherLang repository root:

```bash
unzip -o pantherlang_web_runtime_fix2_nonserve_output.zip
chmod +x bootstrap_web_runtime_fix2_nonserve_output.sh
./bootstrap_web_runtime_fix2_nonserve_output.sh
```

Then verify:

```bash
panther run examples/hello_web/main.pan
panther run examples/hello_api/main.pan
python -m pytest tests/test_web_runtime_fix2_nonserve_output.py tests/test_examples.py -q
python -m pytest -q
```
