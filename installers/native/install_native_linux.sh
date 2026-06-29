#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NATIVE="$ROOT/dist/native/linux-x64/Panther"

if [ ! -x "$NATIVE" ]; then
  echo "Native Linux launcher not found. Run: python3 native_executables/native_builder.py --target linux-x64"
  exit 1
fi

sudo install -m 755 "$NATIVE" /usr/local/bin/Panther
echo "Installed native Panther launcher to /usr/local/bin/Panther"
