#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
from language.compiler.native_backend import PantherNativeBackend
source = 'let message = "PantherLang native backend"\nprint message\nreturn 0'
r=PantherNativeBackend().build(source, module_name='phase6_6_demo')
print('Phase 6.6 demo ok:', r.success)
print('Target:', r.target)
print('Object:', r.object['artifact_path'])
print('Executable:', r.executable['executable_path'])
PY
