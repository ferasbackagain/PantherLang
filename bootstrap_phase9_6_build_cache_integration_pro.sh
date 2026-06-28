#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 9.6 PRO - Build Cache Integration"
echo "============================================================"

mkdir -p toolchain/cache examples/phase9_build_cache scripts docs/phase9 tests/phase9_6

cat > toolchain/cache/build_cache.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any


class BuildCache:
    def __init__(self, root: Path | None = None):
        self.root = root or Path.cwd()
        self.cache_dir = self.root / ".panther_cache" / "build"
        self.cache_dir.mkdir(parents=True, exist_ok=True)

    def fingerprint(self, source: Path, profile: str = "debug") -> str:
        data = source.read_bytes()
        payload = profile.encode() + b"\0" + data
        return hashlib.sha256(payload).hexdigest()

    def cache_file(self, source: Path, profile: str = "debug") -> Path:
        return self.cache_dir / f"{source.stem}.{profile}.json"

    def status(self, source: Path, profile: str = "debug") -> dict[str, Any]:
        source = source.expanduser().resolve()
        digest = self.fingerprint(source, profile)
        cache = self.cache_file(source, profile)
        previous = None
        if cache.exists():
            previous = json.loads(cache.read_text(encoding="utf-8"))
        hit = previous is not None and previous.get("fingerprint") == digest
        return {
            "ok": True,
            "phase": "9.6",
            "source": str(source),
            "profile": profile,
            "fingerprint": digest,
            "cache": str(cache),
            "hit": hit,
            "changed": not hit,
        }

    def update(self, source: Path, profile: str = "debug", artifact: str | None = None) -> dict[str, Any]:
        state = self.status(source, profile)
        payload = {
            "fingerprint": state["fingerprint"],
            "source": state["source"],
            "profile": profile,
            "artifact": artifact,
        }
        Path(state["cache"]).write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
        state["updated"] = True
        return state

    def clear(self) -> dict[str, Any]:
        removed = 0
        if self.cache_dir.exists():
            for item in self.cache_dir.glob("*.json"):
                item.unlink()
                removed += 1
        return {"ok": True, "phase": "9.6", "removed": removed}
PY
chmod +x toolchain/cache/build_cache.py

cat > toolchain/cache/cache_cli.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

from toolchain.cache.build_cache import BuildCache


def main() -> int:
    parser = argparse.ArgumentParser(prog="panther-cache")
    sub = parser.add_subparsers(dest="cmd", required=True)

    status_p = sub.add_parser("status")
    status_p.add_argument("source")
    status_p.add_argument("--profile", default="debug")

    update_p = sub.add_parser("update")
    update_p.add_argument("source")
    update_p.add_argument("--profile", default="debug")
    update_p.add_argument("--artifact", default=None)

    sub.add_parser("clear")

    args = parser.parse_args()
    cache = BuildCache(Path.cwd())

    if args.cmd == "status":
        print(json.dumps(cache.status(Path(args.source), args.profile), indent=2, sort_keys=True))
        return 0

    if args.cmd == "update":
        print(json.dumps(cache.update(Path(args.source), args.profile, args.artifact), indent=2, sort_keys=True))
        return 0

    if args.cmd == "clear":
        print(json.dumps(cache.clear(), indent=2, sort_keys=True))
        return 0

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x toolchain/cache/cache_cli.py

cat > examples/phase9_build_cache/build_cache_demo.panther <<'EOF'
print "Phase 9.6 Build Cache Integration"
EOF

cat > docs/phase9/PHASE_9_6_STATUS.md <<'EOF'
# Phase 9.6 — Build Cache Integration

Completed:
- Build cache engine
- Source fingerprinting
- Profile-aware cache keys
- Cache hit/miss detection
- Cache update/clear commands
- Release build verification
- Regression script

Next: Phase 9.7 — Artifact Packaging.
EOF

# Patch Panther CLI with cache command.
if ! grep -q 'toolchain/cache/cache_cli.py' panther; then
python3 - <<'PY'
from pathlib import Path
p = Path("panther")
txt = p.read_text()
needle = '  toolchain)\n'
insert = '  cache)\n    shift\n    python3 "$ROOT/toolchain/cache/cache_cli.py" "$@"\n    ;;\n\n'
if insert not in txt:
    txt = txt.replace(needle, insert + needle)
p.write_text(txt)
PY
chmod +x panther
fi

cat > scripts/verify_phase9_6_build_cache.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 9.6 Build Cache Verification"
echo "============================================================"

test -f toolchain/cache/build_cache.py
test -f toolchain/cache/cache_cli.py
test -f examples/phase9_build_cache/build_cache_demo.panther
echo "✅ structure tests passed"

python3 -m py_compile toolchain/cache/build_cache.py toolchain/cache/cache_cli.py
echo "✅ python compile passed"

TMP="$(mktemp -d)"
PROJECT_ROOT="$(pwd)"
(
  cd "$TMP"
  "$PROJECT_ROOT/panther" new console CacheApp >/dev/null
  cd CacheApp

  "$PROJECT_ROOT/panther" cache clear >/tmp/p96_clear.json
  grep -q '"ok": true' /tmp/p96_clear.json

  "$PROJECT_ROOT/panther" cache status src/main.panther --profile debug >/tmp/p96_status1.json
  grep -q '"changed": true' /tmp/p96_status1.json
  grep -q '"hit": false' /tmp/p96_status1.json

  "$PROJECT_ROOT/panther" build >/tmp/p96_build.json
  grep -q '"ok": true' /tmp/p96_build.json

  "$PROJECT_ROOT/panther" cache update src/main.panther --profile debug --artifact build/debug/main.sh >/tmp/p96_update.json
  grep -q '"updated": true' /tmp/p96_update.json

  "$PROJECT_ROOT/panther" cache status src/main.panther --profile debug >/tmp/p96_status2.json
  grep -q '"changed": false' /tmp/p96_status2.json
  grep -q '"hit": true' /tmp/p96_status2.json

  echo 'print "changed"' >> src/main.panther
  "$PROJECT_ROOT/panther" cache status src/main.panther --profile debug >/tmp/p96_status3.json
  grep -q '"changed": true' /tmp/p96_status3.json
)
rm -rf "$TMP"
echo "✅ real external project cache tests passed"

./panther build examples/phase9_build_cache/build_cache_demo.panther --release >/tmp/p96_repo_build.json
grep -q '"ok": true' /tmp/p96_repo_build.json
test -f build/release/build_cache_demo.sh
bash build/release/build_cache_demo.sh | grep -q "Phase 9.6 Build Cache Integration"
echo "✅ release build passed"

echo "✅ PantherLang Phase 9.6 Build Cache Integration verification complete."
EOF
chmod +x scripts/verify_phase9_6_build_cache.sh

echo "[phase9.6] Running verification..."
bash scripts/verify_phase9_6_build_cache.sh

echo "============================================================"
echo " Phase 9.6 COMPLETE"
echo " Next: Phase 9.7 Artifact Packaging"
echo "============================================================"
