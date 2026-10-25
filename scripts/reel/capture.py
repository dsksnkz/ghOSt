#!/usr/bin/env python3
"""Export real ghOSt component frames for the showreel, offscreen, with sample data.

Works on a private copy of the shell under .local/reel/runtime; the source tree
and the installed profile are never modified. Existing frames are kept, so
delete a folder to regenerate it.
"""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / '.local/reel'
SAMPLE_TRACK = ('({identity: "Spotify", trackTitle: "Midnight City", trackArtist: "M83", '
                'trackAlbum: "Hurry Up, We\'re Dreaming", length: 243, position: 88, canSeek: true, '
                'canGoPrevious: true, canGoNext: true, canTogglePlaying: true})')


def smooth(value):
    value = min(1, max(0, value))
    return value * value * (3 - 2 * value)


def prepare_runtime():
    runtime = OUTPUT / 'runtime'
    if runtime.exists():
        shutil.rmtree(runtime)
    shutil.copytree(ROOT / 'config/quickshell/ghost-bar', runtime)
    shutil.copy2(Path(__file__).with_name('reel-capture.qml'), runtime / 'reel-capture.qml')
    # Sample media state lives only in this private copy.
    media = runtime / 'MediaPanel.qml'
    text = media.read_text()
    for old, new in (('readonly property var player: Desk.player', 'readonly property var player: ' + SAMPLE_TRACK),
                     ('readonly property bool playing: Desk.playing', 'readonly property bool playing: true')):
        if old not in text:
            raise RuntimeError('MediaPanel changed: review the sample-data adapter')
        text = text.replace(old, new)
    media.write_text(text)
    spectrum = runtime / 'AudioSpectrum.qml'
    spectrum.write_text(spectrum.read_text().replace(
        'property var levels: Array(barCount).fill(0)',
        'property var levels: [.3,.5,.9,.6,.8,.4,.7,.85,.5,.6,.95,.4,.7,.3,.5]'))
    return runtime


def capture():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    runtime = prepare_runtime()
    environment = dict(os.environ)
    for key in ('WAYLAND_DISPLAY', 'HYPRLAND_INSTANCE_SIGNATURE'):
        environment.pop(key, None)
    environment.update(QT_QPA_PLATFORM='offscreen', GHOST_CALENDAR_FIXTURE='1',
                       GHOST_SETTINGS_FIXTURE='1',
                       DBUS_SESSION_BUS_ADDRESS='unix:path=/nonexistent-ghost-reel-bus')
    log_path = OUTPUT / 'renderer.log'
    with log_path.open('w') as log:
        process = subprocess.Popen(['nice', '-n', '10', 'quickshell', '-p', str(runtime / 'reel-capture.qml')],
                                   env=environment, stdout=log, stderr=log)
        try:
            deadline = time.monotonic() + 20
            instance = None
            while time.monotonic() < deadline:
                content = log_path.read_text()
                match = re.search(r'by-id/([^/]+)/log', content)
                if match and 'Configuration Loaded' in content:
                    instance = match.group(1)
                    break
                if process.poll() is not None:
                    raise RuntimeError(content)
                time.sleep(.1)
            if not instance:
                raise RuntimeError('Asset renderer did not become ready')

            def frame(scene, parameters, path):
                if path.exists():
                    return
                path.parent.mkdir(parents=True, exist_ok=True)
                subprocess.run(['quickshell', 'ipc', '-i', instance, 'call', 'reel', 'frame',
                                scene, json.dumps(parameters), str(path)],
                               env=environment, check=True, capture_output=True, timeout=5)
                deadline = time.monotonic() + 6
                while not path.exists():
                    if time.monotonic() > deadline:
                        raise RuntimeError('Frame not written: ' + str(path))
                    time.sleep(.005)
                time.sleep(.02)

            for index in range(40):
                frame('rail', {'pose': min(3, 3 * smooth(index / 39))}, OUTPUT / 'wheel' / f'{index:04d}.png')
            frame('rail', {'pose': 0}, OUTPUT / 'rail.png')
            for index in range(46):
                frame('calendar', {'elapsed': index * 1500 / 45,
                                   'gpu': 12 + 40 * smooth(index / 45), 'cpu': 18 + 30 * smooth(index / 45),
                                   'memory': 30 + 24 * smooth(index / 45)},
                      OUTPUT / 'calendar' / f'{index:04d}.png')
            for index in range(30):
                frame('sidebar', {'reveal': smooth(index / 12), 'elapsed': index * 900 / 29},
                      OUTPUT / 'sidebar' / f'{index:04d}.png')
            for page in ('general', 'network', 'sound', 'wallpaper', 'battery', 'about'):
                frame('settings', {'page': page}, OUTPUT / f'settings-{page}.png')
            frame('media', {}, OUTPUT / 'media.png')
            print('Captured rail, wheel, calendar, sidebar, settings and media frames', flush=True)
            subprocess.run(['quickshell', 'ipc', '-i', instance, 'call', 'reel', 'stop'],
                           env=environment, capture_output=True, timeout=5)
        finally:
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.terminate()
                process.wait(timeout=5)


if __name__ == '__main__':
    capture()
