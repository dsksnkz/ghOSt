#!/usr/bin/env python3
"""Exercise the real picker offscreen; never invoke wallpaper/system actions."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
environment = dict(os.environ, QT_QPA_PLATFORM="offscreen",
                   GHOST_SETTINGS_FIXTURE="1", GHOST_CALENDAR_FIXTURE="1",
                   DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent-ghost-test-bus")
environment.pop("WAYLAND_DISPLAY", None)
environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
if len(sys.argv) > 1:
    capture = Path(sys.argv[1]).resolve()
    capture.mkdir(parents=True, exist_ok=True)
    environment["GHOST_PICKER_CAPTURE_DIR"] = str(capture)
with tempfile.TemporaryDirectory(prefix="ghost-wallpaper-picker-") as directory:
    runtime = Path(directory) / "runtime"
    shutil.copytree(ROOT / "config/quickshell/ghost-bar", runtime)
    entry = runtime / "picker-test.qml"
    shutil.copyfile(ROOT / "tests/wallpaper-picker.qml", entry)
    fixture = Path(directory) / "Images"
    fixture.mkdir()
    (fixture / "Empty folder").mkdir()
    for name in ("Coast #1.webp", "Night.webp"):
        shutil.copyfile(ROOT / "site/assets/wallpaper.webp", fixture / name)
    shutil.copyfile(entry, fixture / "Broken.jpg")
    shutil.copyfile(entry, fixture / "Not an image.txt")
    environment["GHOST_PICKER_FIXTURE"] = fixture.as_uri()
    result = subprocess.run(["quickshell", "-p", str(entry)], env=environment,
                            capture_output=True, text=True, timeout=20)
output = result.stdout + result.stderr
assert result.returncode == 0, output
assert "PASS: dark wallpaper browser" in output, output
assert not any(error in output for error in ("FAIL!", "ReferenceError", "TypeError", "Binding loop")), output
print("PASS: wallpaper chooser input/render and no wallpaper mutation")
