#!/usr/bin/env python3
"""Verify and capture a fixture-only preview; never send native actions."""
import json
import os
from pathlib import Path
import subprocess
import sys
import time

instance, output = sys.argv[1], Path(sys.argv[2]).resolve()
output.mkdir(parents=True, exist_ok=True)
env = dict(os.environ)
env.pop('WAYLAND_DISPLAY', None)
env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)

def call(*args):
    return subprocess.check_output(['quickshell', 'ipc', '-i', instance,
                                   'call', 'preview', *args], env=env, text=True)

def capture(name):
    path = output / (name + '.png')
    call('capture', str(path))
    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        if path.exists() and path.stat().st_size:
            return
        time.sleep(.02)
    raise RuntimeError('Capture did not complete: ' + str(path))

call('page', 'calendar')
call('calendar', 'reduced', 'false')
call('page', 'settings')
for page in ('general', 'sound', 'battery', 'widgets', 'brightness', 'wallpaper',
             'notifications', 'network', 'bluetooth', 'airplane',
             'accessibility', 'storage', 'applications', 'about'):
    state = json.loads(call('settings', 'page', page))
    assert state['preview'] and state['visible'] and state['page'] == page
    assert (state['width'], state['height'], state['categories']) == (1024, 699, 14)
    assert not state['error']
    time.sleep(.25)
    capture('settings-' + page)
call('settings', 'query', 'no-such-category')
time.sleep(.2)
capture('settings-empty-search')
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
print('PASS: 14 Settings pages, geometry, empty search, random grouped sidebar, long-name render, component captures and calendar Settings navigation')
