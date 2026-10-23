#!/usr/bin/env python3
"""Offscreen Settings/editor/rail test; never modifies desktop preferences."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
environment = dict(os.environ, QT_QPA_PLATFORM="offscreen", GHOST_SETTINGS_FIXTURE="1",
                   GHOST_CALENDAR_FIXTURE="1", DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent-ghost-layout-bus")
environment.pop("WAYLAND_DISPLAY", None)
environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
if len(sys.argv) > 1:
    capture = Path(sys.argv[1]).resolve()
    capture.mkdir(parents=True, exist_ok=True)
    environment["GHOST_LAYOUT_CAPTURE_DIR"] = str(capture)
with tempfile.TemporaryDirectory(prefix="ghost-rail-layout-") as directory:
    runtime = Path(directory) / "runtime"
    shutil.copytree(root / "config/quickshell/ghost-bar", runtime)
    entry = runtime / "layout-test.qml"
    shutil.copyfile(root / "tests/rail-layout.qml", entry)
    result = subprocess.run(["quickshell", "-p", str(entry)], env=environment,
                            capture_output=True, text=True, timeout=20)
output = result.stdout + result.stderr
assert result.returncode == 0 and "PASS: dark Settings render" in output, output
assert not any(error in output for error in ("FAIL!", "ReferenceError", "TypeError", "Binding loop")), output
print("PASS: Settings theme, editor input and rail layout integration")
