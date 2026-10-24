#!/usr/bin/env python3
"""Test launcher geometry/rendering offscreen without launching any command."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
environment = dict(os.environ, QT_QPA_PLATFORM="offscreen", GHOST_SETTINGS_FIXTURE="1",
                   GHOST_CALENDAR_FIXTURE="1", DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent-ghost-motion-bus")
environment.pop("WAYLAND_DISPLAY", None)
environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
if len(sys.argv) > 1:
    capture = Path(sys.argv[1]).resolve()
    capture.mkdir(parents=True, exist_ok=True)
    environment["GHOST_MOTION_CAPTURE_DIR"] = str(capture)
with tempfile.TemporaryDirectory(prefix="ghost-launcher-motion-") as directory:
    runtime = Path(directory) / "runtime"
    shutil.copytree(root / "config/quickshell/ghost-bar", runtime)
    entry = runtime / "motion-test.qml"
    shutil.copyfile(root / "tests/launcher-motion.qml", entry)
    result = subprocess.run(["quickshell", "-p", str(entry)], env=environment,
                            capture_output=True, text=True, timeout=15)
output = result.stdout + result.stderr
assert result.returncode == 0 and "PASS: launcher slides from above screen" in output, output
assert not any(error in output for error in ("FAIL!", "ReferenceError", "TypeError", "Binding loop")), output
print("PASS: launcher slide-only geometry and other-popup regression checks")
