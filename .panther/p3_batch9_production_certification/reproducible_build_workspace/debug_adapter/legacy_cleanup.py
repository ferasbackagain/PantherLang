from pathlib import Path


LEGACY_FAILED_TESTS = [
    "tests/test_h4_2_part2b_dap_execution_routing.py",
    "tests/test_h4_2_part2_finalize_execution_control.py",
]


def find_active_legacy_failed_tests():
    return [path for path in LEGACY_FAILED_TESTS if Path(path).exists()]


def validate_legacy_cleanup():
    active = find_active_legacy_failed_tests()
    if active:
        raise RuntimeError("legacy failed Part2B tests still active: " + ", ".join(active))
    return True
