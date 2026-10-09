#!/usr/bin/env python3
"""Verify and capture a fixture-only preview; never send native actions."""
import json
import os
from pathlib import Path
import subprocess
import sys
import time
from urllib.parse import unquote
from PIL import Image

instance, output = sys.argv[1], Path(sys.argv[2]).resolve()
output.mkdir(parents=True, exist_ok=True)
env = dict(os.environ)
env.pop('WAYLAND_DISPLAY', None)
env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)

def call(*args):
    return subprocess.check_output(['quickshell', 'ipc', '-i', instance,
                                   'call', '--', 'preview', *args], env=env, text=True)

def capture(name):
    path = output / (name + '.png')
    previous_mtime = path.stat().st_mtime_ns if path.exists() else 0
    call('capture', str(path))
    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        if path.exists() and path.stat().st_size and path.stat().st_mtime_ns > previous_mtime:
            try:
                with Image.open(path) as rendered:
                    pixels = rendered.convert('RGB')
                    assert pixels.size == (1920, 1080)
                    if name != 'settings-name-editor':
                        assert pixels.getpixel((800, 30)) == (25, 25, 25), 'Rail missing from composition'
                        assert pixels.getpixel((1800, 100)) == (21, 21, 21), 'Reference background changed'
                    else:
                        assert pixels.getpixel((840, 480)) != (37, 37, 37), 'PC-name dialog missing from capture'
                return
            except OSError:
                pass  # Qt may still be completing the asynchronous PNG write.
        time.sleep(.02)
    raise RuntimeError('Capture did not complete: ' + str(path))

call('page', 'calendar')
call('calendar', 'reduced', 'false')
call('page', 'settings')
call('settings', 'reset', '')
for page in ('general', 'sound', 'battery', 'widgets', 'brightness', 'wallpaper',
             'notifications', 'network', 'bluetooth', 'airplane',
             'accessibility', 'storage', 'applications', 'about'):
    state = json.loads(call('settings', 'page', page))
    assert state['preview'] and state['visible'] and state['page'] == page
    assert (state['width'], state['height'], state['categories']) == (1024, 699, 14)
    assert (state['x'], state['y'], state['scale']) == (524, 212, 1)
    assert state['navHeight'] == 538 and state['navTop'] == 137
    assert (state['searchTop'], state['searchWidth']) == (84, 227)
    assert (state['portraitTop'], state['portraitSize'], state['portraitRadius']) == (18, 48, 11)
    assert state['profileFont'] == 'JetBrains Mono'
    assert len(state['groupHeights']) == 4 and state['groupHeights'][0] == 234
    assert state['groupCategories'][0] == ['network', 'bluetooth', 'general', 'airplane', 'accessibility']
    assert not state['error']
    time.sleep(.25)
    capture('settings-' + page)
call('settings', 'query', 'no-such-category')
time.sleep(.2)
capture('settings-empty-search')
call('settings', 'query', '')
call('settings', 'page', 'general')
for origin in ('sidebar', 'general'):
    state = json.loads(call('settings', 'portrait', origin))
    assert state['portraitChooserRequested'] and state['portraitOrigin'] == origin
state = json.loads(call('settings', 'portrait-select', state['portraitSource']))
assert not state['portraitChooserRequested']
fixture_picture = Path(__file__).resolve().parents[1] / 'site/assets/wallpaper.webp'
state = json.loads(call('settings', 'portrait-select', fixture_picture.as_uri()))
assert unquote(state['portraitSource']) == unquote(fixture_picture.as_uri())
time.sleep(.35)
capture('settings-portrait-fixture')
with Image.open(output / 'settings-general.png') as before, Image.open(output / 'settings-portrait-fixture.png') as after:
    for box in ((541,230,589,278), (1109,265,1225,381)):
        assert before.crop(box).tobytes() != after.crop(box).tobytes(), 'Portrait did not update'
call('settings', 'reset', '')
state = json.loads(call('settings', 'name-open', ''))
assert state['nameEditor'] and state['nameValid'] and state['nameDraft'] == 'unit-001'
time.sleep(.2)
capture('settings-name-editor')
for invalid in ('--reboot', 'invalid name', 'UPPERCASE', '-edge', 'edge-', 'x' * 64):
    state = json.loads(call('settings', 'name-draft', invalid))
    assert not state['nameValid']
    assert json.loads(call('settings', 'name-save', ''))['nameEditor']
call('settings', 'name-cancel', '')
assert json.loads(call('settings', 'reset', ''))['displayHost'] == 'Unit-01'
call('settings', 'name-open', '')
call('settings', 'name-draft', 'unit-002')
state = json.loads(call('settings', 'name-save', ''))
assert not state['nameEditor'] and state['displayHost'] == 'unit-002'
capture('settings-name-fixture')
call('settings', 'reset', '')
call('settings', 'query', 'sound')
state = json.loads(call('settings', 'query', 'sound'))
assert state['groupCategories'] == [['sound']]
capture('settings-search-sound')
call('settings', 'query', '')
call('page', 'sidebar')
first = json.loads(call('sidebar', 'reveal'))
second = json.loads(call('sidebar', 'reveal'))
assert second['elapsed'] < 100
assert sorted(second['order']) == list(range(6))
assert first['order'] != second['order']
time.sleep(1)
assert json.loads(call('sidebar', 'normal'))['elapsed'] == 900
capture('sidebar-frame')
call('sidebar', 'long')
time.sleep(.2)
capture('sidebar-long-names')
call('sidebar', 'normal')
for page in ('desktop', 'calendar', 'rail', 'session'):
    call('page', page)
    time.sleep(1.6)
    capture('power-frame' if page == 'session' else page + '-frame')
call('page', 'calendar')
call('calendar', 'navigate', 'settings')
assert json.loads(call('settings', 'page', 'general'))['visible']
print('PASS: 14 Settings pages, separate groups, portrait entry points, fixture-only name validation/save/cancel, search, sidebar, captures and calendar navigation')
