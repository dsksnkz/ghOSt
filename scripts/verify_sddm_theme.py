#!/usr/bin/env python3
"""Verify the ghOSt SDDM theme offscreen with stand-in SDDM objects.

Never installs the theme, edits SDDM configuration or contacts the SDDM daemon.
Optional argument: path for a 1920x1080 preview PNG.
"""
import os
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
theme = root / "config/sddm/ghost"
environment = dict(os.environ, QT_QPA_PLATFORM="offscreen",
                   GHOST_SDDM_THEME=str(theme),
                   DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent-ghost-test-bus")
environment.pop("WAYLAND_DISPLAY", None)
environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
if len(sys.argv) > 1:
    environment["GHOST_SDDM_CAPTURE"] = str(Path(sys.argv[1]).resolve())
result = subprocess.run(["quickshell", "-p", str(root / "tests/sddm-theme.qml")], env=environment,
                        capture_output=True, text=True, timeout=20)
output = result.stdout + result.stderr
assert result.returncode == 0, output
assert "PASS: sddm theme renders" in output, output
assert not any(error in output for error in ("FAIL!", "ReferenceError", "TypeError", "Binding loop")), output
print("PASS: SDDM theme login, failure, session and layout behaviour")
