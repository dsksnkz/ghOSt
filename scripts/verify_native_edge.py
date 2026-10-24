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
try:
    for side, edge_x in [('left', x), ('right', x + width - 1)]:
        move(edge_x, y + 50)
        time.sleep(2.4)
        assert not state()['opened'], 'Top dead zone opened OSD'
        volume = state()['amount']
        move(edge_x, y + height // 2)
        current = state()
        assert current['opened'] and current['side'] == side, current
        assert current['amount'] == volume, 'Hover changed volume'
        move(edge_x, y + height - 10)
        time.sleep(2.4)
        assert not state()['opened'], 'Bottom dead zone kept OSD open'
    print('PASS: native left/right edge hover, top/bottom dead zones, expiry and unchanged volume')
finally:
    move(pointer['x'], pointer['y'])
