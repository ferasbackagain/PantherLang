from pathlib import Path
import importlib.util
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
SANDBOX = ROOT / ".panther" / "p3_atomic_replacement" / "sandbox_atomic_switch"


def test_sandbox_contains_legacy_and_promoted_debug_adapter():
    assert (SANDBOX / "debug_adapter_legacy").exists()
    assert (SANDBOX / "debug_adapter").exists()
    assert (SANDBOX / "debug_adapter" / "protocol.py").exists()
    assert (SANDBOX / "debug_adapter" / "server.py").exists()


def test_sandbox_promoted_adapter_imports_as_debug_adapter():
    code = """
import sys
from pathlib import Path
sandbox = Path('.panther/p3_atomic_replacement/sandbox_atomic_switch').resolve()
sys.path.insert(0, str(sandbox))
from debug_adapter.protocol import encode_message, read_message
from debug_adapter.server import DebugServer
from io import StringIO
msg={'seq':1,'type':'request','command':'initialize','arguments':{'adapterID':'panther'}}
framed=encode_message(msg)
assert read_message(StringIO(framed)) == msg
server=DebugServer()
assert server.dispatch({'seq':1,'command':'initialize','arguments':{'adapterID':'panther'}})['success'] is True
launch=server.dispatch({'seq':2,'command':'launch','arguments':{'program':'main.pan'}})
assert launch['type']=='event'
assert launch['event']=='process'
print('sandbox promoted debug_adapter OK')
"""
    proc = subprocess.run([sys.executable, "-c", code], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stdout + proc.stderr


def test_live_runtime_was_not_replaced():
    live = ROOT / "debug_adapter"
    rebuilt = ROOT / "debug_adapter_rebuilt"
    assert live.exists()
    assert rebuilt.exists()
    assert live.resolve() != rebuilt.resolve()
