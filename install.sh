#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
for dep in quickshell hyprctl python3; do
    command -v "$dep" >/dev/null || { printf 'Missing dependency: %s\n' "$dep" >&2; exit 1; }
done
python3 scripts/install.py "$@"
