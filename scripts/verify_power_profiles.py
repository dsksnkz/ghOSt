#!/usr/bin/env python3
"""Offscreen preview buttons never change the laptop's power profile."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
environment = dict(os.environ, QT_QPA_PLATFORM="offscreen")
environment.pop("WAYLAND_DISPLAY", None)
environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
with tempfile.TemporaryDirectory(prefix="ghost-power-test-") as directory:
    runtime = Path(directory) / "runtime"
    shutil.copytree(root / "config/quickshell/ghost-bar", runtime)
    entry = runtime / "power-test.qml"
    shutil.copyfile(root / "tests/power-profiles.qml", entry)
    result = subprocess.run(["quickshell", "-p", str(entry)], env=environment,
                            capture_output=True, text=True, timeout=10)
output = result.stdout + result.stderr
assert result.returncode == 0, output
assert "PASS: three profile buttons, normal mapping, observed selection and unavailable performance guard; no live changes" in output, output
assert not any(error in output for error in ("FAIL!", "ReferenceError", "TypeError", "Binding loop")), output
print("PASS: power profile controls and preview isolation")
