#!/usr/bin/env python3
"""Exercise only an isolated preview IPC target, never a desktop session action."""
import json
import os
import subprocess
import sys
import time

instance = sys.argv[1]
env = dict(os.environ)
env.pop('WAYLAND_DISPLAY', None)

def call(*args):
    return subprocess.check_output(['quickshell', 'ipc', '-i', instance, 'call', 'preview', *args], env=env, text=True)

def state():
    return json.loads(call('telemetry'))

call('calendar', 'reduced', 'false')
call('opened', 'true')
first = json.loads(call('calendar', 'reveal', ''))
assert first['elapsed'] < 250
second = json.loads(call('calendar', 'reveal', ''))
assert sorted(second['order']) == list(range(6)) and first['order'] != second['order']
time.sleep(1.65)
assert state()['elapsed'] == 1500
assert abs(state()['width']/state()['height'] - 1200/505) < .01
call('calendar', 'weather', 'rain')
a = state()['weatherMotion']['rain']
time.sleep(.25)
assert state()['weatherMotion']['rain'] != a
call('calendar', 'reduced', 'true')
a = state()['weatherMotion']['rain']
time.sleep(.2)
assert state()['weatherMotion']['rain'] == a
call('calendar', 'reduced', 'false')
call('calendar', 'weather', 'storm')
samples = []
for _ in range(48):
    samples.append(state()['weatherMotion']['lightning'])
    time.sleep(.1)
assert max(samples)-min(samples) > .2
call('opened', 'false')
assert not state()['active'] and not state()['weatherMotion']['moving']
call('opened', 'true')
call('calendar', 'reduced', 'true')
assert state()['elapsed'] == 1500
print('PASS: ratio, random reveal, 1.5s completion, rain motion, storm pulse, reduced motion, closed-state suspension')
