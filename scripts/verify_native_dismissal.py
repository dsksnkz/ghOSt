#!/usr/bin/env python3
"""Opt-in real Hyprland pointer test; an inert guard prevents application clicks."""
import argparse
import json
import os
from pathlib import Path
import re
import select
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]


def run(*arguments, **options):
    return subprocess.check_output(arguments, text=True, timeout=3, **options)


def production(method, *arguments):
    return run('quickshell', 'ipc', '-c', 'ghost-bar', 'call', 'bar', method, *arguments)


def verify(page, button, escape=False, capture_dir=None):
    initial = json.loads(production('status'))
    assert not (initial['sidebar'] or initial['panel'] or initial['settings']), 'Close ghOSt panels before testing'
    cursor = json.loads(run('hyprctl', 'cursorpos', '-j'))
    environment = dict(os.environ, YDOTOOL_SOCKET=f'/run/user/{os.getuid()}/.ydotool_socket')
    process = subprocess.Popen(['quickshell', '-p', str(ROOT / 'tests/native-click-guard.qml')],
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    try:
        output = b''
        deadline = time.monotonic() + 2
        instance = None
        while time.monotonic() < deadline:
            if select.select([process.stdout], [], [], .05)[0]:
                output += os.read(process.stdout.fileno(), 4096)
            match = re.search(rb'by-id/([^/]+)/log', output)
            if match and b'Configuration Loaded' in output:
                instance = match.group(1).decode()
                break
        assert instance, output.decode()

        def guard():
            return json.loads(run('quickshell', 'ipc', '-i', instance, 'call', 'input-check', 'status'))['presses']

        def click(x, y):
            run('ydotool', 'mousemove', '-a', '-x', str(x), '-y', str(y), env=environment)
            actual = json.loads(run('hyprctl', 'cursorpos', '-j'))
            assert actual == {'x': x, 'y': y}, actual
            run('ydotool', 'click', '-D', '10', button, env=environment)
            time.sleep(.3)

        time.sleep(.15)
        control = guard()
        click(1100, 700)
        assert guard() > control, 'Positive control: injected clicks did not reach the inert guard'

        if page == 'sidebar':
            production('sidebar')
        else:
            production('toggle', page)
        time.sleep(.25)
        opened = json.loads(production('status'))
        assert opened['sidebar'] if page == 'sidebar' else opened['panel'] == page, opened
        before = json.loads(production('dismissal'))[0]
        protected = guard()
        if capture_dir:
            assert page == 'sidebar', 'Captures are deliberately limited to the privacy-safe header'
            capture_dir.mkdir(parents=True, exist_ok=True)
            run('grim', '-g', '0,100 380x83', str(capture_dir / 'sidebar-open-native.png'))
        # Blank inner frame, no settings/radio/audio/session actions.
        if page == 'sidebar' and not escape:
            click(10, 200)
            assert json.loads(production('status'))['sidebar'], 'Inside click dismissed Sidebar'
            assert json.loads(production('dismissal'))[0]['presses'] == before['presses']
            assert guard() == protected, 'Sidebar hole passed through to guard'
        if escape:
            run('ydotool', 'key', '1:1', '1:0', env=environment)
            time.sleep(.3)
        else:
            click(1100, 700)
        after = json.loads(production('status'))
        diagnostic = json.loads(production('dismissal'))[0]
        assert not after['sidebar'] and not after['panel'], (page, after['sidebar'], diagnostic, protected, guard())
        if not escape:
            assert (diagnostic['presses'] > before['presses'] or
                    diagnostic['focusDismissals'] > before['focusDismissals']), 'No native dismissal event received'
        assert guard() == protected, 'Outside press reached underlying guard'
        if capture_dir:
            run('grim', '-g', '0,100 380x83', str(capture_dir / 'sidebar-closed-native.png'))
        event = 'Escape' if escape else button
        print(f'PASS: native {page} {event}, closed, no click-through')
    finally:
        try:
            production('close')
        finally:
            # Cleanup still runs if the production IPC request fails.
            # Only this child is stopped; its 5s timer is a second safeguard.
            process.terminate()
            try:
                process.wait(timeout=1)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=1)
            run('ydotool', 'mousemove', '-a', '-x', str(cursor['x']), '-y', str(cursor['y']), env=environment)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native', action='store_true', help='explicitly permit a brief native input test')
    parser.add_argument('--page', choices=['sidebar', 'calendar', 'media'], default='sidebar')
    parser.add_argument('--button', choices=['0xC0', '0xC1', '0xC2'], default='0xC0')
    parser.add_argument('--escape', action='store_true', help='verify native Escape instead of an outside press')
    parser.add_argument('--capture-dir', type=Path, help='save safe header crops over the inert guard')
    args = parser.parse_args()
    if not args.native:
        parser.error('Requires --native; sends real pointer events to owned test surfaces')
    verify(args.page, args.button, args.escape, args.capture_dir)
