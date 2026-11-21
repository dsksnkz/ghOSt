#!/usr/bin/env python3
"""Check corrected geometry/fonts and motion only in the isolated fixture."""
import json
import os
import subprocess
import sys
import time

instance = sys.argv[1]
env = dict(os.environ)
env.pop('WAYLAND_DISPLAY', None)
env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)


def call(*args):
    return subprocess.check_output(
        ['quickshell', 'ipc', '-i', instance, 'call', 'preview', *args],
        env=env, text=True)


call('page', 'desktop')
state = json.loads(call('polish'))
assert state['railFonts'], 'No rendered rail labels inspected'
assert all(label['family'] == 'Adwaita Sans'
           for label in state['railFonts']), state['railFonts']
actions = {button['hint']: button for button in state['panelControls']}
for name in ('Applications', 'Settings', 'Power'):
    assert actions[name]['radius'] == 15, actions[name]
print('PASS: all rendered rail fonts and 15px panel controls')
