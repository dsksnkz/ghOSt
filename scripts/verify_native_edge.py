#!/usr/bin/env python3
"""Opt-in native hover test: moves/restores pointer, never clicks or changes volume."""
import argparse
import json
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--allow-pointer', action='store_true')
if not parser.parse_args().allow_pointer:
    raise SystemExit('Use --allow-pointer deliberately; hover OSDs will be briefly visible.')
if subprocess.run(['pgrep', '-x', 'cs2'], stdout=subprocess.DEVNULL).returncode == 0:
    raise SystemExit('Refusing pointer tests while CS2 is running.')


def query(*args):
    return json.loads(subprocess.check_output(args, text=True))


def state():
    return query('quickshell', 'ipc', '-c', 'ghost-bar', 'call', 'bar', 'edgeVolume')


def move(x, y):
    subprocess.run(['ydotool', 'mousemove', '-a', '-x', str(x), '-y', str(y)], check=True)
    time.sleep(.25)


pointer = query('hyprctl', 'cursorpos', '-j')
monitors = query('hyprctl', 'monitors', '-j')
screen = monitors[0]
x, y = screen['x'], screen['y']
width, height = round(screen['width'] / screen['scale']), round(screen['height'] / screen['scale'])
visible_ids = {screen['activeWorkspace']['id'], screen.get('specialWorkspace', {}).get('id', 0)}
if any(workspace['id'] in visible_ids and workspace.get('hasfullscreen', False)
       for workspace in query('hyprctl', 'workspaces', '-j')):
    raise SystemExit('Refusing pointer tests on a fullscreen output; edge input is intentionally disabled.')
try:
    for side, edge_x in [('left', x), ('right', x + width - 1)]:
        volume = state()['amount']
        for target_y in (10, 50, height // 2 - 90, height // 2 + 90, height - 10):
            move(x + width // 2, y + height // 2)
            assert not state()['edgeHeld'], 'Leaving the edge did not release the OSD'
            move(edge_x, y + target_y)
            assert not state()['edgeHeld'], 'OSD bypassed the 0.5s dwell'
            time.sleep(.4)
            actual_pointer = query('hyprctl', 'cursorpos', '-j')
            assert abs(actual_pointer['x'] - edge_x) <= 1, ('Pointer did not reach edge', actual_pointer)
            local_y = actual_pointer['y'] - y
            current = state()
            assert current['opened'] and current['side'] == side, current
            assert abs(current['pointerY'] - local_y) <= 1, (current, actual_pointer)
            layers = query('hyprctl', 'layers', '-j')
            osds = [layer for output in layers.values()
                    for group in output['levels'].values() for layer in group
                    if layer['namespace'] == 'ghost-osd']
            assert len(osds) == 1, osds
            expected = y + max(0, min(height - 310, round(local_y - 155)))
            assert abs(osds[0]['y'] - expected) <= 1, (osds[0], expected)
            assert current['amount'] == volume, 'Pointer tracking changed volume'
            spawn_y = current['pointerY']
            move(edge_x, y + height // 2)
            assert state()['pointerY'] == spawn_y, 'Latched OSD followed vertical movement'
            time.sleep(2.4)
            assert state()['opened'], 'OSD expired while the pointer remained at the edge'
        move(x + width // 2, y + height // 2)
        assert not state()['opened'], 'OSD did not close after leaving edge'
    print('PASS: native full-height 0.5s dwell, fixed origin, edge hold/release and unchanged volume')
finally:
    move(pointer['x'], pointer['y'])
