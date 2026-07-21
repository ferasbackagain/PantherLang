from panther_core.version import (
    PANTHERLANG_VERSION,
    PANTHERLANG_RELEASE_NAME,
    get_release_info,
    get_version,
)
from cli.version import get_version as cli_get_version
from runtime.version import get_version as runtime_get_version


def test_unified_version_core_contract():
    assert PANTHERLANG_VERSION == "2.0.0"
    assert PANTHERLANG_RELEASE_NAME == "PantherLang v2.0.0"
    assert get_version() == "2.0.0"
    info = get_release_info()
    assert info["product"] == "PantherLang"
    assert info["version"] == "2.0.0"
    assert info["debug_adapter_version"] == "2.0.0"


def test_cli_and_runtime_version_bridge():
    assert cli_get_version() == "2.0.0"
    assert runtime_get_version() == "2.0.0"