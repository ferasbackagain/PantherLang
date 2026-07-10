from panther_core.version import (
    PANTHERLANG_VERSION,
    PANTHERLANG_RELEASE_NAME,
    get_release_info,
    get_version,
)
from cli.version import get_version as cli_get_version
from runtime.version import get_version as runtime_get_version


def test_unified_version_core_contract():
    assert PANTHERLANG_VERSION == "1.1.7"
    assert PANTHERLANG_RELEASE_NAME == "PantherLang v1.1.7"
    assert get_version() == "1.1.7"
    info = get_release_info()
    assert info["product"] == "PantherLang"
    assert info["version"] == "1.1.7"
    assert info["debug_adapter_version"] == "1.1.7"


def test_cli_and_runtime_version_bridge():
    assert cli_get_version() == "1.1.7"
    assert runtime_get_version() == "1.1.7"
