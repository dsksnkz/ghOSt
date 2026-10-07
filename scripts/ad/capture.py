#!/usr/bin/env python3
"""Render real ghOSt components with private, non-destructive demonstration data."""
import json
import math
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / '.local/ad-production-hq'
FPS = 30


def smooth(value):
    value = min(1, max(0, value))
    return value * value * (3 - 2 * value)


def capture():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    runtime = OUTPUT / 'runtime'
    shutil.copytree(ROOT / 'config/quickshell/ghost-bar', runtime, dirs_exist_ok=True)
    shutil.copy2(Path(__file__).with_name('advert.qml'), runtime / 'advert.qml')
    # A renderer-only property feeds volume without touching PipeWire.
    rail_path = runtime / 'Rail.qml'
    rail = rail_path.read_text()
    original = 'readonly property int displayVolume: fixtureMode ? 33 : Desk.volume'
    if original not in rail:
        raise RuntimeError('Rail source changed: review the isolated fixture adapter')
    rail_path.write_text(rail.replace(original,
        'property int fixtureVolume: 33\n    readonly property int displayVolume: fixtureMode ? fixtureVolume : Desk.volume'))

    environment = dict(os.environ)
    for key in ('WAYLAND_DISPLAY', 'HYPRLAND_INSTANCE_SIGNATURE'):
        environment.pop(key, None)
    environment.update(QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
                       GHOST_CALENDAR_FIXTURE='1')
    log_path = OUTPUT / 'renderer.log'
    with log_path.open('w') as log:
        process = subprocess.Popen(['quickshell', '-p', str(runtime / 'advert.qml')],
                                   env=environment, stdout=log, stderr=log)
        try:
            deadline = time.monotonic() + 15
            instance = None
            while time.monotonic() < deadline:
                match = re.search(r'by-id/([^/]+)/log', log_path.read_text())
                if match and 'Configuration Loaded' in log_path.read_text():
                    instance = match.group(1)
                    break
                if process.poll() is not None:
                    raise RuntimeError(log_path.read_text())
                time.sleep(.1)
            if not instance:
                raise RuntimeError('Asset renderer did not become ready')

            def frame(scene, parameters, path):
                subprocess.run(['quickshell', 'ipc', '-i', instance, 'call', 'advert',
                                'frame', scene, json.dumps(parameters), str(path)],
                               env=environment, check=True, capture_output=True, timeout=5)
                deadline = time.monotonic() + 5
                while not path.exists():
                    if time.monotonic() > deadline:
                        raise RuntimeError('Frame not written: ' + str(path))
                    time.sleep(.005)

            sequences = {'wheel': 90, 'volume': 66, 'calendar': 150, 'sidebar': 90}
            for name, count in sequences.items():
                folder = OUTPUT / ('calendar-framed' if name == 'calendar' else name)
                folder.mkdir(exist_ok=True)
                for index in range(count):
                    moment = index / FPS
                    params = {}
                    scene = 'rail' if name in ('wheel', 'volume') else name
                    if name == 'wheel':
                        turn = min(2, int(moment / .9))
                        pose = turn + smooth((moment % .9) / .35)
                        params = {'pose': min(3, pose)}
                    elif name == 'volume':
                        params = {'volume': round(24 + 52 * smooth(moment / 1.2)
                                                  - 14 * smooth((moment - 1.4) / .6))}
                    elif name == 'calendar':
                        params = {'elapsed': min(1500, index * 1000 / FPS),
                                  'gpu': 18 + 30 * smooth((moment - 1.5) / 1.2),
                                  'cpu': 25 + 18 * math.sin(moment),
                                  'clock': moment >= 3, 'month': 9 if moment >= 4 else 8,
                                  'condition': 'rain' if moment >= 2.3 else 'storm'}
                    elif name == 'sidebar':
                        params = {'reveal': smooth(moment / .28),
                                  'elapsed': min(900, index * 1000 / FPS)}
                    path = folder / f'{index:04d}.png'
                    if path.exists():
                        continue
                    frame(scene, params, path)
                print(f'{name}: {count} real QML frames', flush=True)
            for page in ('general', 'battery', 'storage', 'about'):
                path = OUTPUT / f'settings-{page}.png'
                if not path.exists():
                    frame('settings', {'page': page}, path)
                print('Settings: ' + page, flush=True)
            subprocess.run(['quickshell', 'ipc', '-i', instance, 'call', 'advert', 'stop'],
                           env=environment, capture_output=True, timeout=5)
        finally:
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.terminate()
                process.wait(timeout=5)


if __name__ == '__main__':
    capture()
