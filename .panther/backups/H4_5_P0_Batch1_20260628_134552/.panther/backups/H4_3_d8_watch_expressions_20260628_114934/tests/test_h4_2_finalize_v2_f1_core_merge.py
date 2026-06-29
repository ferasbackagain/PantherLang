from debug_adapter.finalize_v2_guard import (
    validate_debug_adapter_architecture,
    validate_no_known_broken_part2b_signature,
)
from debug_adapter.finalize_v2_status import H4_2_FINALIZE_V2


def test_h4_2_finalize_v2_architecture_guard():
    result = validate_debug_adapter_architecture()
    assert result["status"] == "ok"
    assert result["missing"] == []


def test_h4_2_finalize_v2_no_known_broken_part2b_signature():
    assert validate_no_known_broken_part2b_signature() is True


def test_h4_2_finalize_v2_status_marker():
    assert H4_2_FINALIZE_V2["f1_core_merge"] is True
