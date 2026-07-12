"""PantherLang unified product version."""

PANTHERLANG_VERSION = "1.1.8"
PANTHERLANG_RELEASE_NAME = "PantherLang v1.1.8"
PANTHERLANG_RELEASE_CHANNEL = "stable"
PANTHERLANG_DEBUG_ADAPTER_VERSION = "1.1.8"

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