#!/usr/bin/env bash
# Rebuild the checked-in Qt 6 shader; installation uses the ready-made package.
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
shader_compiler="${QSB:-/usr/lib/qt6/bin/qsb}"
if [[ ! -x "$shader_compiler" ]]; then
    echo "Qt 6 qsb is unavailable; the bundled shader does not need rebuilding." >&2
    exit 1
fi
shader_dir="$project_dir/config/quickshell/ghost-bar/shaders"
"$shader_compiler" --qsbversion 64 --glsl '100 es,120,150' --hlsl 50 --msl 12 \
    -o "$shader_dir/liquid.frag.qsb" "$shader_dir/liquid.frag"
