#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/../language"
python3 panther.py run examples/store.panther
