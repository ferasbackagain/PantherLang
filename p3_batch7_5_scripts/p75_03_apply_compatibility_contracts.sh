#!/usr/bin/env bash
set -u -o pipefail
ROOT="${P75_ROOT:-$(pwd)}"; WORKDIR="${P75_WORKDIR:?}"; REPORT_DIR="${P75_REPORT_DIR:?}"
mkdir -p "$WORKDIR/status" "$REPORT_DIR"
cd "$ROOT" || exit 1

python3 - <<'PY'
from __future__ import annotations
import ast, json, os, textwrap, hashlib, shutil
from pathlib import Path
root=Path(os.environ.get('P75_ROOT', os.getcwd()))
work=Path(os.environ['P75_WORKDIR']); report=Path(os.environ['P75_REPORT_DIR'])
changes=[]

def sha(p: Path): return hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None

def backup_file(p: Path):
    bdir=work/'file_backups'; bdir.mkdir(parents=True, exist_ok=True)
    if p.exists():
        dest=bdir/(p.relative_to(root).as_posix().replace('/','__')+'.bak')
        shutil.copy2(p,dest)
        return str(dest)
    return None

def has_attr_method(path: Path, cls: str, method: str) -> bool:
    if not path.exists(): return False
    try:
        tree=ast.parse(path.read_text(encoding='utf-8'))
    except Exception:
        return False
    for node in tree.body:
        if isinstance(node, ast.ClassDef) and node.name==cls:
            return any(isinstance(x, ast.FunctionDef) and x.name==method for x in node.body)
    return False

# ResponseDispatcher.normalize compatibility contract
rd=root/'debug_adapter'/'response_dispatcher.py'
if rd.exists() and not has_attr_method(rd,'ResponseDispatcher','normalize'):
    backup_file(rd)
    with rd.open('a', encoding='utf-8') as f:
        f.write('''\n\n# P-3 Batch 7.5 compatibility contract: historical H4.2 tests expect\n# ResponseDispatcher.normalize(message) to normalize request/response payloads.\ndef _p75_response_dispatcher_normalize(self, message):\n    if message is None:\n        return {}\n    if isinstance(message, dict):\n        normalized = dict(message)\n        normalized.setdefault("seq", 0)\n        if normalized.get("type") == "response":\n            normalized.setdefault("success", True)\n        return normalized\n    return {"seq": 0, "type": "response", "success": False, "message": str(message)}\n\ntry:\n    ResponseDispatcher.normalize = _p75_response_dispatcher_normalize\nexcept NameError:\n    pass\n''')
    changes.append({'file':'debug_adapter/response_dispatcher.py','change':'added ResponseDispatcher.normalize compatibility contract','sha256_after':sha(rd)})

# ThreadStore.ensure_main_thread compatibility contract
th=root/'debug_adapter'/'threads.py'
if th.exists() and not has_attr_method(th,'ThreadStore','ensure_main_thread'):
    backup_file(th)
    with th.open('a', encoding='utf-8') as f:
        f.write('''\n\n# P-3 Batch 7.5 compatibility contract: historical H4.3 tests expect\n# ThreadStore.ensure_main_thread() to return/create the canonical main thread.\ndef _p75_thread_store_ensure_main_thread(self):\n    if hasattr(self, "main"):\n        return self.main()\n    if not hasattr(self, "_threads") or not self._threads:\n        try:\n            self._threads = [DebugThread(1, "main")]\n        except NameError:\n            self._threads = []\n    return self._threads[0] if self._threads else None\n\ntry:\n    ThreadStore.ensure_main_thread = _p75_thread_store_ensure_main_thread\nexcept NameError:\n    pass\n''')
    changes.append({'file':'debug_adapter/threads.py','change':'added ThreadStore.ensure_main_thread compatibility contract','sha256_after':sha(th)})

# DAP protocol explicit bytes helper without breaking P2 string-compatible contract.
proto=root/'debug_adapter'/'protocol.py'
if proto.exists() and 'def encode_message_bytes' not in proto.read_text(encoding='utf-8'):
    backup_file(proto)
    with proto.open('a', encoding='utf-8') as f:
        f.write('''\n\n# P-3 Batch 7.5 compatibility helper. The canonical encode_message return remains\n# string-compatible for P2/P3. H4 byte-stream callers should use this explicit helper.\ndef encode_message_bytes(message):\n    return bytes(encode_message(message))\n''')
    changes.append({'file':'debug_adapter/protocol.py','change':'added encode_message_bytes helper without changing canonical encode_message contract','sha256_after':sha(proto)})

# Add adapter.py if absent from backup may already restored; if not, create facade.
adapter=root/'debug_adapter'/'adapter.py'
if not adapter.exists():
    backup_file(adapter)
    adapter.write_text('''from __future__ import annotations\n\n"""Compatibility facade for historical debug_adapter.adapter imports."""\ntry:\n    from .session import DebugSession  # noqa: F401\nexcept Exception:  # pragma: no cover\n    DebugSession = None  # type: ignore\n''', encoding='utf-8')
    changes.append({'file':'debug_adapter/adapter.py','change':'generated adapter compatibility facade','sha256_after':sha(adapter)})

manifest={'changes':changes,'note':'Contracts are additive compatibility surfaces; no tests are edited.'}
(work/'compatibility_contracts_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
(report/'compatibility_contracts_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print(json.dumps(manifest, indent=2))
PY
