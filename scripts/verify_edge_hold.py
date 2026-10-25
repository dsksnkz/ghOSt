#!/usr/bin/env python3
"""Nonvisual timer/state test with fake audio/settings: no cursor, sound or window."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
           DBUS_SESSION_BUS_ADDRESS='unix:path=/nonexistent-ghost-edge-test')
env.pop('WAYLAND_DISPLAY', None)
env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
with tempfile.TemporaryDirectory(prefix='ghost-edge-hold-') as directory:
    runtime = Path(directory)
    for name in ('EdgeHold.qml', 'OsdState.qml'):
        shutil.copy2(ROOT / 'config/quickshell/ghost-bar' / name, runtime / name)
    for file in (ROOT / 'tests/edge-stubs').iterdir():
        shutil.copy2(file, runtime / file.name)
    shutil.copy2(ROOT / 'tests/edge-hold.qml', runtime / 'test.qml')
    result = subprocess.run(['quickshell', '-p', str(runtime / 'test.qml')], env=env,
                            capture_output=True, text=True, timeout=12)
output = result.stdout + result.stderr
assert result.returncode == 0 and 'PASS: 500ms dwell/cancel' in output, output
assert not any(error in output for error in ('FAIL!', 'ReferenceError', 'TypeError')), output
print('PASS: nonvisual production dwell/latch/expiry state with fake audio and settings')
