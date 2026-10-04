#!/usr/bin/env python3
"""Exercise native QML motion through a fixture-only target; no desktop dispatch."""
import json
import os
from pathlib import Path
import subprocess
import sys
import time

instance, directory = sys.argv[1], Path(sys.argv[2]).resolve()
directory.mkdir(parents=True, exist_ok=True)
environment = dict(os.environ)
environment.pop('WAYLAND_DISPLAY', None)
environment.pop('HYPRLAND_INSTANCE_SIGNATURE', None)

def call(*arguments):
    return subprocess.check_output(['quickshell', 'ipc', '-i', instance, 'call',
                                   '--', 'preview', *arguments], env=environment, text=True)

def wheel(action='state', value=''):
    return json.loads(call('workspace', action, value))

def settle():
    time.sleep(.4)
    state = wheel()
    assert not state['moving'] and abs(state['position'] - state['target']) < 1e-6
    central = min(state['rendered'], key=lambda item: abs(item['offset']))
    assert central['workspace'] == state['current'] and central['x'] == 36
    return state

def capture(name):
    path = directory / (name + '.png')
    before = path.stat().st_mtime_ns if path.exists() else 0
    call('capture', str(path))
    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        if path.exists() and path.stat().st_mtime_ns > before and path.stat().st_size:
            return
        time.sleep(.02)
    raise AssertionError('Missing capture: ' + name)

call('page', 'rail')
wheel('reduced', 'false')
wheel('windows', 'json:[]')
wheel('current', '5')
triangle = settle()['triangle']
state = wheel('current', '1')
assert state['moving'] and state['target'] == 5, state
time.sleep(.08)
state = wheel()
assert 4 < state['position'] < 5 and state['triangle'] == triangle
assert any(abs(item['rotation']) > 1 for item in state['rendered'])
assert any(item['y'] > 10 and .733 < item['scale'] < 1 for item in state['rendered'])
assert settle()['current'] == 1
capture('rail-wrap-one')
assert [item['workspace'] for item in wheel()['rendered']] == [5,1,2]
wheel('current', '5')
assert settle()['position'] == 4

# Multiple and fractional notches use the same eligible ring as the backend.
state = wheel('scroll', '-360')
assert state['current'] == 3 and state['target'] == 7
settle()
state = wheel('scroll', '60')
assert state['current'] == 3 and state['remainder'] == .5
state = wheel('scroll', '60')
assert state['current'] == 2 and state['remainder'] == 0
settle()
wheel('windows', 'json:[{"id":8,"windows":2},{"id":6,"windows":0}]')
wheel('current', '5')
settle()
assert wheel('scroll', '-120')['current'] == 8
settle()
assert wheel('scroll', '-120')['current'] == 1
settle()

# An empty higher desktop opened manually remains visible but is skipped by scroll.
wheel('windows', 'json:[]')
wheel('current', '7')
settle()
assert wheel('scroll', '-120')['current'] == 1
settle()
wheel('current', '7')
settle()
assert wheel('scroll', '120')['current'] == 5
settle()

# Retargeting preserves the current fractional pose instead of jumping to a digit.
wheel('current', '1')
settle()
wheel('current', '2')
time.sleep(.06)
before = wheel()
after = wheel('current', '3')
assert before['moving'] and after['moving']
assert 0 < after['position'] < 1 and after['target'] == 2
assert settle()['current'] == 3
wheel('reduced', 'true')
state = wheel('current', '4')
assert not state['moving'] and state['position'] == state['target']
wheel('reduced', 'false')
wheel('current', '5')
settle()
capture('rail-frame')
for name, phase in [('wheel-quarter',4.25), ('wheel-half',4.5), ('wheel-three-quarter',4.75)]:
    wheel('pose', str(phase))
    assert wheel()['triangle'] == triangle
    capture(name)
wheel('current', '1')
settle()
call('page', 'desktop')
time.sleep(1.7)
capture('desktop-frame')
call('page', 'rail')
for target in (2,3,4,5):
    wheel('current', str(target))
    start = time.monotonic()
    for frame in range(12):
        capture('motion-%03d' % ((target-2)*12+frame))
        time.sleep(max(0, start+(frame+1)*.04-time.monotonic()))
print('PASS: projected rotation/depth, stationary triangle, wrap, eligible higher desktops, accumulated notches, continuous retarget, reduced motion and actual captures')
