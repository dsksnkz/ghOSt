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
call('sidebar', 'reveal')
state = json.loads(call('polish'))
assert state['railFonts'], 'No rendered rail labels inspected'
assert all(label['family'] == 'JetBrainsMono Nerd Font Mono'
           for label in state['railFonts']), state['railFonts']
buttons = {button['hint']: button for button in state['sidebarControls']}
for name in ('Power', 'Settings', 'Enable do not disturb'):
    assert buttons[name]['radius'] == 15, buttons[name]
    assert buttons[name]['offset'] < 0, 'Entrance must start left of target'
for name in ('Toggle Wi-Fi', 'Toggle Bluetooth', 'Network 01', 'Mouse'):
    assert buttons[name]['radius'] == 11, buttons[name]
actions = {button['hint']: button for button in state['panelControls']}
for name in ('Applications', 'Settings', 'Power'):
    assert actions[name]['radius'] == 15, actions[name]
time.sleep(1)
state = json.loads(call('polish'))
assert all(button['offset'] == 0 for button in state['sidebarControls'])
print('PASS: all rendered rail fonts, 15/11px controls, left-to-right entrance and settled offsets')
