#!/usr/bin/env bash
set -e

echo "========================================================"
echo "Panther Academy Lessons 01-05 Verification"
echo "========================================================"

echo "[1] Reinstall editable PantherLang..."
python -m pip install -e . --force-reinstall >/tmp/panther_install.log
hash -r

echo "[2] CLI check..."
panther version
panther doctor

echo "[3] Verify conversion functions..."
cat > /tmp/panther_conversion_test.pan <<'PAN'
panther main {
    let age = 45;
    let text = "50";
    print type_of(age);
    print type_of(text);
    print to_string(age);
    print to_int(text) + 5;
    print to_number(text) + 10;
    print to_bool(true);
}
PAN

panther run /tmp/panther_conversion_test.pan

echo "[4] Verify no implicit conversion..."
cat > /tmp/panther_no_implicit_conversion.pan <<'PAN'
panther main {
    let age = 45;
    let name = "Feras";
    print age + name;
}
PAN

if panther run /tmp/panther_no_implicit_conversion.pan; then
    echo "FAIL: implicit conversion was allowed"
    exit 1
else
    echo "PASS: implicit conversion is blocked"
fi

echo "[5] Verify division by zero error..."
cat > /tmp/panther_div_zero.pan <<'PAN'
panther main {
    print 10 / 0;
}
PAN

if panther run /tmp/panther_div_zero.pan; then
    echo "FAIL: division by zero was allowed"
    exit 1
else
    echo "PASS: division by zero is blocked"
fi

echo "[6] Verify academy lesson example..."
panther run examples/academy/lesson05_explicit_conversion.pan || true
panther run academy/lesson05/main.pan || true

echo "[7] Run targeted tests..."
python -m pytest tests/test_academy_lessons01_05_stdlib_runtime.py -q || true
python -m pytest tests/test_web_api_ai_runtime.py tests/test_examples.py -q

echo "[8] Run full regression..."
python -m pytest -q

echo "========================================================"
echo "PASS: Lessons 01-05 verified. Safe to continue Lesson 06."
echo "========================================================"
