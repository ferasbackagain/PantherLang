"""PantherLang unified product version."""

PANTHERLANG_VERSION = "2.0.0"
PANTHERLANG_RELEASE_NAME = "PantherLang v2.0.0"
PANTHERLANG_RELEASE_CHANNEL = "stable"
PANTHERLANG_DEBUG_ADAPTER_VERSION = "2.0.0"

def get_version():
    return PANTHERLANG_VERSION

def get_release_info():
    return {
        "product": "PantherLang",
        "version": PANTHERLANG_VERSION,
        "release_name": PANTHERLANG_RELEASE_NAME,
        "release_channel": PANTHERLANG_RELEASE_CHANNEL,
        "debug_adapter_version": PANTHERLANG_DEBUG_ADAPTER_VERSION,
    }