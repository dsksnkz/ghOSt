#!/usr/bin/env python3
"""Verify the workspace switcher offscreen with fixture workspaces; no dispatch or capture."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
environment = dict(os.environ, QT_QPA_PLATFORM="offscreen", GHOST_SETTINGS_FIXTURE="1",
                   DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent-ghost-test-bus")
environment.pop("WAYLAND_DISPLAY", None)
environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
if len(sys.argv) > 1:
    captures = Path(sys.argv[1]).resolve()
    captures.mkdir(parents=True, exist_ok=True)
    environment["GHOST_SWITCHER_CAPTURE_DIR"] = str(captures)
with tempfile.TemporaryDirectory(prefix="ghost-switcher-") as directory:
    runtime = Path(directory) / "runtime"
    shutil.copytree(root / "config/quickshell/ghost-bar", runtime)
    entry = runtime / "switcher-test.qml"
    shutil.copyfile(root / "tests/workspace-switcher.qml", entry)
    result = subprocess.run(["quickshell", "-p", str(entry)], env=environment,
                            capture_output=True, text=True, timeout=25)
output = result.stdout + result.stderr
assert result.returncode == 0, output
assert "PASS: switcher geometry" in output, output
assert not any(error in output for error in ("FAIL!", "ReferenceError", "TypeError", "Binding loop")), output
print("PASS: workspace switcher geometry and input")
