#!/usr/bin/env bash
#
# PantherLang Installer — Linux / macOS
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ferasbackagain/PantherLang/main/install.sh | bash
#   # NOTE: This requires install.sh to be pushed to main branch root on GitHub first
#   # or
#   ./install.sh
#
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
PIP_INSTALL="${PIP_INSTALL:-pip3}"

echo "PantherLang Installer"
echo "====================="

# Check Python availability
if ! command -v python3 &>/dev/null; then
    echo "ERROR: Python 3.10+ is required but not found."
    echo "Install Python from https://python.org or your package manager."
    exit 1
fi

PY_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "Python version: $PY_VERSION"

# Install via pip
echo ""
echo "Installing pantherlang..."
$PIP_INSTALL install --upgrade pantherlang 2>/dev/null || {
    echo "Trying pip install from local source..."
    cd "$(dirname "${BASH_SOURCE[0]}")"
    $PIP_INSTALL install -e . 2>/dev/null || {
        echo "ERROR: pip install failed. Try: pip3 install pantherlang"
        exit 1
    }
}

# Verify installation
echo ""
echo "Verifying installation..."
if command -v panther &>/dev/null; then
    echo "PantherLang installed successfully!"
    panther version
    echo ""
    echo "Try: panther doctor"
else
    echo ""
    echo "WARNING: 'panther' command not found on PATH."
    echo "Ensure ~/.local/bin is in your PATH, or run:"
    echo "  export PATH=\$HOME/.local/bin:\$PATH"
fi
