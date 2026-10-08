#!/usr/bin/env python3
"""Compile real UI types without creating a preview, window or system action."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
environment = dict(os.environ, QT_QPA_PLATFORM='wayland',
                   GHOST_SETTINGS_FIXTURE='1', GHOST_CALENDAR_FIXTURE='1')
with tempfile.TemporaryDirectory(prefix='ghost-compile-') as directory:
    destination = Path(directory) / 'config'
    shutil.copytree(ROOT / 'config/quickshell/ghost-bar', destination)
    shutil.copyfile(ROOT / 'tests/compile-surfaces.qml', destination / 'compile.qml')
    try:
        result = subprocess.run(['quickshell', '-p', str(destination / 'compile.qml')],
                                env=environment, capture_output=True, text=True, timeout=10)
    except subprocess.TimeoutExpired as error:
        raise AssertionError((error.stdout or b'').decode() + (error.stderr or b'').decode()) from error
    output = result.stdout + result.stderr
    assert result.returncode == 0 and 'PASS: production surfaces compile' in output, output
    print('PASS: production surfaces compile without instantiating windows or actions')
