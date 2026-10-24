#!/usr/bin/env python3
"""Real offscreen input and safe capture; emitted actions never reach the system."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
           GHOST_SETTINGS_FIXTURE='1', GHOST_CALENDAR_FIXTURE='1')
env.pop('WAYLAND_DISPLAY', None)
env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
if len(sys.argv) > 1:
    env['GHOST_INTRO_CAPTURE'] = str(Path(sys.argv[1]).resolve())
with tempfile.TemporaryDirectory(prefix='ghost-intro-test-') as directory:
    runtime = Path(directory) / 'runtime'
    shutil.copytree(ROOT / 'config/quickshell/ghost-bar', runtime)
    shutil.copy2(ROOT / 'tests/intro.qml', runtime / 'test.qml')
    result = subprocess.run(['quickshell', '-p', str(runtime / 'test.qml')],
                            env=env, capture_output=True, text=True, timeout=15)
output = result.stdout + result.stderr
assert result.returncode == 0 and 'PASS: Intro real keyboard search' in output, output
assert 'FAIL!' not in output and 'TypeError' not in output and 'ReferenceError' not in output, output
print('PASS: Intro input/search/actions/reset/close and safe capture')
