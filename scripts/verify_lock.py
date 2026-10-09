#!/usr/bin/env python3
"""Exercise lock visuals and mocked PAM outcomes without locking a session."""
import os
from pathlib import Path
import subprocess
import shutil
import tempfile

root = Path(__file__).resolve().parents[1]
environment = dict(os.environ, QT_QPA_PLATFORM=os.environ.get("GHOST_LOCK_TEST_PLATFORM", "offscreen"))
if environment["QT_QPA_PLATFORM"] == "offscreen":
    environment.pop("WAYLAND_DISPLAY", None)
    environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
with tempfile.TemporaryDirectory(prefix="ghost-lock-test-") as directory:
    runtime = Path(directory) / "runtime"
    shutil.copytree(root / "config/quickshell/ghost-bar", runtime)
    entry = runtime / "lock-test.qml"
    shutil.copyfile(root / "tests/lock-scene.qml", entry)
    try:
        result = subprocess.run(["quickshell", "-p", str(entry)],
                                env=environment, capture_output=True, text=True, timeout=15)
    except subprocess.TimeoutExpired as error:
        raise AssertionError((error.stdout or b"").decode() + (error.stderr or b"").decode()) from error
output = result.stdout + result.stderr
assert result.returncode == 0, output
assert "PASS: lock descent, first key, masked submit, PAM failures/success, stationary rotation and reduced motion" in output, output
assert "FAIL!" not in output, output
assert not any(error in output for error in ("ReferenceError", "TypeError", "Binding loop")), output
print("PASS: lock visuals, input and mocked authentication policy; no real lock or PAM call")
