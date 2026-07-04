# PantherLang Academy Lessons 01-05 Stdlib + Runtime Fix

Run from the PantherLang repository root:

```bash
unzip -o pantherlang_academy_lesson05_stdlib_fix.zip
chmod +x bootstrap_academy_lessons01_05_stdlib_fix.sh
./bootstrap_academy_lessons01_05_stdlib_fix.sh
```

Manual checks:

```bash
panther run examples/academy/lesson05_conversions.pan
python -m pytest tests/academy/test_lesson05_runtime_polish.py -q
python -m pytest -q
```
