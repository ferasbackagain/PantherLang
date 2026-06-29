from compiler.version import get_version as compiler_version
from toolchain.version import get_version as toolchain_version
from panther_core.version import get_version

def test_versions():
    assert get_version()=="1.0.0"
    assert compiler_version()=="1.0.0"
    assert toolchain_version()=="1.0.0"
