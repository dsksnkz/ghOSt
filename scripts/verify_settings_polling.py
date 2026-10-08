#!/usr/bin/env python3
"""Check actual Settings timers/processes without a window or system backend."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
PAGES = ('network', 'bluetooth', 'general', 'airplane', 'accessibility',
         'sound', 'battery', 'widgets', 'brightness', 'wallpaper',
         'notifications', 'storage', 'applications', 'about')
FAST_PAGES = {'battery', 'brightness', 'storage'}


def verify(fixture_mode=False):
    environment = dict(os.environ, QT_QPA_PLATFORM='offscreen',
                       GHOST_SETTINGS_FIXTURE='1' if fixture_mode else '0')
    for key in ('WAYLAND_DISPLAY', 'HYPRLAND_INSTANCE_SIGNATURE'):
        environment.pop(key, None)
    with tempfile.TemporaryDirectory(prefix='ghost-settings-polling-') as directory:
        destination = Path(directory)
        for asset in (ROOT / 'tests/settings-polling').iterdir():
            if asset.is_file():
                shutil.copyfile(asset, destination / asset.name)
        shutil.copyfile(ROOT / 'config/quickshell/ghost-bar/Settings.qml',
                        destination / 'Settings.qml')
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
                    raise RuntimeError('Settings timer test did not load')

                def call(method, *arguments):
                    result = subprocess.run(
                        ['quickshell', 'ipc', '-i', instance, 'call', 'poll-test',
                         method, *arguments], env=environment, check=True,
                        capture_output=True, text=True, timeout=3)
                    return json.loads(result.stdout) if method != 'stop' else None

                def settled():
                    deadline = time.monotonic() + 3
                    while time.monotonic() < deadline:
                        status = call('status')
                        if not status['queryRunning']:
                            return status
                        time.sleep(.02)
                    raise RuntimeError('Mock Settings backend did not finish')

                baseline = settled()['queries']
                assert baseline == (0 if fixture_mode else 1), 'Unexpected startup query count'
                for page in PAGES:
                    status = call('configure', 'false', page)
                    expected = 5000 if page in FAST_PAGES else 60000
                    assert status['interval'] == expected, (page, status)
                    assert not status['timerRunning'] and status['queries'] == baseline

                if fixture_mode:
                    status = call('configure', 'true', 'brightness')
                    assert not status['timerRunning'] and status['queries'] == 0
                    call('stop')
                    print('PASS: fixture mode suppresses startup, open and periodic backend queries')
                    return

                call('configure', 'true', 'general')
                opened = settled()
                assert opened['queries'] == baseline + 1 and opened['timerRunning']
                time.sleep(5.3)
                assert settled()['queries'] == opened['queries'], 'General must not poll every 5s'

                call('page', 'storage')
                storage = settled()
                assert storage['queries'] == opened['queries'] + 1, 'Page change needs a fresh read'
                time.sleep(5.3)
                assert settled()['queries'] == storage['queries'] + 1, 'Storage must retain 5s updates'

                closed = call('configure', 'false', 'storage')
                time.sleep(5.3)
                assert settled()['queries'] == closed['queries'], 'Hidden Settings must not poll'
                call('configure', 'true', 'brightness')
                assert settled()['queries'] == closed['queries'] + 1, 'Reopen must refresh immediately'
                output = log_path.read_text()
                assert 'WARN' not in output and 'ERROR' not in output, output
                call('stop')
                print('PASS: 14 page intervals, startup/open/page refresh, real 5s timer and hidden release')
            finally:
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.terminate()
                    process.wait(timeout=3)


if __name__ == '__main__':
    verify()
    verify(fixture_mode=True)
