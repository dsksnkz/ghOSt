#!/usr/bin/env python3
"""Verify isolated rail input/rendering without desktop or private MPRIS access."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import sys

root = Path(__file__).resolve().parents[1]
environment = dict(os.environ, QT_QPA_PLATFORM="offscreen",
                   GHOST_CALENDAR_FIXTURE="1", GHOST_SETTINGS_FIXTURE="1",
                   DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent-ghost-test-bus")
environment.pop("WAYLAND_DISPLAY", None)
environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
if len(sys.argv) > 1:
    captures = Path(sys.argv[1]).resolve()
    captures.mkdir(parents=True, exist_ok=True)
    environment['GHOST_RAIL_CAPTURE_DIR'] = str(captures)
with tempfile.TemporaryDirectory(prefix="ghost-rail-clock-") as directory:
    runtime = Path(directory) / "runtime"
    shutil.copytree(root / "config/quickshell/ghost-bar", runtime)
    entry = runtime / "rail-clock-test.qml"
    shutil.copyfile(root / "tests/rail-clock.qml", entry)
    result = subprocess.run(["quickshell", "-p", str(entry)], env=environment,
                            capture_output=True, text=True, timeout=10)
output = result.stdout + result.stderr
assert result.returncode == 0, output
assert "PASS: center contains only clock, exact centering at two widths and calendar click retained" in output, output
assert not any(error in output for error in ("FAIL!", "ReferenceError", "TypeError", "Binding loop")), output
print("PASS: clock-only rail, centering and calendar access")
