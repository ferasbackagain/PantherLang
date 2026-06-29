from debug_adapter.legacy_cleanup import (
    find_active_legacy_failed_tests,
    validate_legacy_cleanup,
)
from debug_adapter.finalize_v2_status import H4_2_FINALIZE_V2


def test_legacy_failed_tests_are_retired():
    assert find_active_legacy_failed_tests() == []
    assert validate_legacy_cleanup() is True


def test_f2_status_marker():
    assert H4_2_FINALIZE_V2["f2_legacy_cleanup"] is True
