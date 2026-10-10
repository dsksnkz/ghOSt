#!/usr/bin/env python3
"""Offscreen command UI checks; previewMode prohibits process execution."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
environment = dict(os.environ, QT_QPA_PLATFORM="offscreen")
environment.pop("WAYLAND_DISPLAY", None)
environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
with tempfile.TemporaryDirectory(prefix="ghost-launcher-test-") as directory:
    runtime = Path(directory) / "runtime"
    shutil.copytree(root / "config/quickshell/ghost-bar", runtime)
    entry = runtime / "launcher-test.qml"
    shutil.copyfile(root / "tests/launcher-commands.qml", entry)
    result = subprocess.run(["quickshell", "-p", str(entry)], env=environment,
                            capture_output=True, text=True, timeout=10)
output = result.stdout + result.stderr
assert result.returncode == 0, output
assert "PASS: launcher terminal row, explicit Enter, no command execution, no command pinning and app-search restoration" in output, output
assert "PASS: fresh-open query reset and animated selection outline in both directions" in output, output
assert "PASS: keyboard viewport scroll is interpolated, synchronized and retargets rapid keys" in output, output
assert "PASS: Escape from command input requests closure and clears input without execution" in output, output
assert not any(error in output for error in ("FAIL!", "ReferenceError", "TypeError", "Binding loop")), output
print("PASS: launcher command UI, Enter dispatch and preview execution guard")
