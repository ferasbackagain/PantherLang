#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET="/usr/local/bin/Panther"

sudo tee "$TARGET" >/dev/null <<SH
#!/usr/bin/env bash
set -euo pipefail
ROOT="$ROOT"
exec "\$ROOT/panther" "\$@"
SH

sudo chmod +x "$TARGET"
echo "Panther installed to $TARGET"
