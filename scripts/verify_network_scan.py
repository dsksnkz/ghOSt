#!/usr/bin/env python3
"""Exercise scanner-demand bindings without a window, radio or network service."""
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
    with tempfile.TemporaryDirectory(prefix='ghost-scan-binding-') as directory:
        # Quickshell confines relative imports to its configuration tree.
        fixture = Path(directory) / 'network-scan-binding.qml'
        shutil.copyfile(ROOT / 'tests/network-scan-binding.qml', fixture)
        shutil.copyfile(ROOT / 'config/quickshell/ghost-bar/NetworkScanPolicy.js',
                        Path(directory) / 'NetworkScanPolicy.js')
        log_path = Path(directory) / 'renderer.log'
        with log_path.open('w') as log:
            process = subprocess.Popen(
                ['quickshell', '-p', str(fixture)],
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
                    raise RuntimeError('Windowless Qt test did not load')

                def configure(state, requested, first, second=False):
                    result = subprocess.run(
                        ['quickshell', 'ipc', '-i', instance, 'call', 'scan-test',
                         'configure', json.dumps(state)],
                        env=environment, check=True, capture_output=True, text=True, timeout=3)
                    actual = json.loads(result.stdout)
                    expected = {'requested': requested, 'first': first, 'second': second}
                    assert actual == expected, (state, actual, expected)

                configure({}, False, False)
                configure({'sidebarOpen': True}, True, True)
                configure({'sidebarOpen': True, 'sidebarNetworkEnabled': False}, False, False)
                configure({'settingsOpen': True, 'settingsPage': 'network'}, True, True)
                configure({'settingsOpen': True, 'settingsPage': 'sound'}, False, False)
                configure({'panel': 'network'}, True, True)
                configure({'panel': 'network', 'wifiEnabled': False}, False, False)
                configure({'sidebarOpen': True}, True, True)
                configure({'sidebarOpen': True, 'device': 'second'}, True, False, True)
                configure({'sidebarOpen': True, 'device': 'none'}, False, False)
                configure({'sidebarOpen': True}, True, True)
                configure({}, False, False)
                output = log_path.read_text()
                assert 'WARN' not in output and 'ERROR' not in output, output
                subprocess.run(
                    ['quickshell', 'ipc', '-i', instance, 'call', 'scan-test', 'stop'],
                    env=environment, check=True, capture_output=True, timeout=3)
                print('PASS: 12 windowless Qt scan-demand, page, radio and device-swap transitions')
            finally:
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.terminate()
                    process.wait(timeout=3)


if __name__ == '__main__':
    verify()
