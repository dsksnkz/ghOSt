#!/usr/bin/env python3
"""Exercise the production Settings router without a window or system action."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]


def verify():
    environment = dict(os.environ, QT_QPA_PLATFORM='offscreen')
    for key in ('WAYLAND_DISPLAY', 'HYPRLAND_INSTANCE_SIGNATURE'):
        environment.pop(key, None)
    with tempfile.TemporaryDirectory(prefix='ghost-settings-navigation-') as directory:
        destination = Path(directory)
        shutil.copyfile(ROOT / 'tests/settings-navigation.qml', destination / 'shell.qml')
        shutil.copyfile(ROOT / 'config/quickshell/ghost-bar/SettingsNavigation.qml',
                        destination / 'SettingsNavigation.qml')
        log_path = destination / 'renderer.log'
        with log_path.open('w') as log:
            process = subprocess.Popen(
                ['quickshell', '-p', str(destination / 'shell.qml')],
                env=environment, stdout=log, stderr=log)
            try:
                deadline = time.monotonic() + 10
                instance = None
                while time.monotonic() < deadline:
                    output = log_path.read_text()
                    match = re.search(r'by-id/([^/]+)/log', output)
                    if match and 'Configuration Loaded' in output:
                        instance = match.group(1)
                        break
                    if process.poll() is not None:
                        raise RuntimeError(output)
                    time.sleep(.05)
                if not instance:
                    raise RuntimeError('Settings navigation test did not load')

                def call(method, *arguments):
                    result = subprocess.run(
                        ['quickshell', 'ipc', '-i', instance, 'call', 'navigation-test',
                         method, *arguments], env=environment, check=True,
                        capture_output=True, text=True, timeout=3)
                    return json.loads(result.stdout) if method == 'status' else None

                def check(parameters, page, choices, active=True):
                    call('configure', json.dumps(parameters))
                    deadline = time.monotonic() + 3
                    expected = dict(active=active, page=page, choices=choices, focuses=choices)
                    while time.monotonic() < deadline:
                        actual = call('status')
                        if actual == expected:
                            return
                        time.sleep(.02)
                    raise AssertionError((parameters, actual, expected))

                check({}, 'general', 0, active=False)
                check({'requests': ['storage']}, 'general', 0, active=False)
                check({'active': True}, 'storage', 1)
                check({'requests': ['battery']}, 'battery', 2)
                # The requested page may be unchanged while the user browses locally.
                check({'localPage': 'network', 'requests': ['battery']}, 'battery', 3)
                check({'requests': ['battery']}, 'battery', 4)
                check({'requests': ['network', 'brightness', 'about']}, 'about', 5)
                check({'requests': ['general'], 'closeBeforeRoute': True},
                      'about', 5, active=False)
                check({'active': True}, 'general', 6)
                check({'active': False}, 'general', 6, active=False)
                output = log_path.read_text()
                assert 'WARN' not in output and 'ERROR' not in output, output
                call('stop')
                print('PASS: 10 actual Qt routing transitions, repeat/burst requests and close-before-route guard')
            finally:
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.terminate()
                    process.wait(timeout=3)


if __name__ == '__main__':
    verify()
