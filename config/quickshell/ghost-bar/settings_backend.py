#!/usr/bin/env python3
"""ghOSt Settings: bounded standard-service queries and explicit user actions."""
import argparse
from datetime import datetime
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import time
from urllib.parse import unquote, urlparse

DEFAULTS = {'reducedMotion': False, 'usageTracking': False, 'widgets': {
    'network': True, 'bluetooth': True, 'volume': True,
    'brightness': True, 'notifications': True}}

def paths():
    home = Path.home()
    return (Path(os.environ.get('XDG_CONFIG_HOME', home/'.config'))/'ghost/settings.json',
            Path(os.environ.get('XDG_STATE_HOME', home/'.local/state'))/'ghost/usage.json')

def run(argv):
    result = subprocess.run(argv, capture_output=True, text=True, timeout=3)
    if result.returncode:
        raise ValueError(result.stderr.strip()[:240] or 'Service unavailable')
    return result.stdout.strip()

def load(path, default):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return json.loads(json.dumps(default))

def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(value, indent=2)+'\n')
    temporary.chmod(0o600)
    temporary.replace(path)

def preferences():
    data = load(paths()[0], DEFAULTS)
    if not isinstance(data, dict):
        data = {}
    result = json.loads(json.dumps(DEFAULTS))
    for key in ('reducedMotion', 'usageTracking'):
        if type(data.get(key)) is bool:
            result[key] = data[key]
    for key in result['widgets']:
        if isinstance(data.get('widgets'),dict) and type(data['widgets'].get(key)) is bool:
            result['widgets'][key] = data['widgets'][key]
    for key in ('wallpaper', 'profilePicture'):
        if isinstance(data.get(key), str):
            result[key] = data[key]
    return result

def setting(key, value):
    if value not in ('true', 'false'):
        raise ValueError('Expected true or false')
    data = preferences()
    if key in ('reducedMotion', 'usageTracking'):
        data[key] = value == 'true'
    elif key.startswith('widgets.') and key[8:] in DEFAULTS['widgets']:
        data['widgets'][key[8:]] = value == 'true'
    else:
        raise ValueError('Unknown setting')
    save(paths()[0], data)

def battery():
    for device in Path('/sys/class/power_supply').glob('*'):
        try:
            if (device/'type').read_text().strip() != 'Battery':
                continue
            def read(name):
                try:
                    return (device/name).read_text().strip()
                except OSError:
                    return None
            return {'percent': int(read('capacity')), 'status': read('status'),
                    'cycles': read('cycle_count')}
        except (OSError, ValueError, TypeError):
            continue
    return None

def usage(record=False):
    path = paths()[1]
    data = load(path, {'days': {}, 'last': None})
    if not isinstance(data,dict) or not isinstance(data.get('days'),dict):
        data = {'days': {}, 'last': None}
    day = datetime.now().astimezone().date().isoformat()
    if record and preferences()['usageTracking']:
        now = time.time()
        previous = data.get('last')
        # No backfill across restarts, sleep or missed samples; count only
        # observed intervals, never an inferred full day's activity.
        elapsed = now-previous if isinstance(previous, (int,float)) else 0
        if 0 < elapsed <= 75 and data.get('day') == day:
            monitors = json.loads(run(['hyprctl', '-j', 'monitors']))
            if any(m.get('dpmsStatus') for m in monitors):
                data['days'][day] = min(86400, data['days'].get(day, 0)+elapsed)
        data.update(last=now, day=day)
        data['days'] = dict(sorted(data['days'].items())[-30:])
        reading = battery()
        if reading:
            samples = data.get('samples', [])
            samples.append({'time': now, 'percent': reading['percent'], 'status': reading['status']})
            data['samples'] = samples[-1440:]
        save(path, data)
    samples = data.get('samples', [])
    return {'seconds': round(data.get('days', {}).get(day, 0)),
            'days': data.get('days', {}), 'samples': samples[-120:]}

def status():
    result = {'host': platform.node(), 'kernel': platform.release(),
              'preferences': preferences(), 'battery': battery(), 'usage': usage(),
              'brightness': None, 'notifications': None,
              'equalizer': bool(shutil.which('easyeffects'))}
    try:
        value = run(['brightnessctl', '-m']).split(',')
        if len(value)>3 and value[1] == 'backlight':
            result['brightness'] = {'device': value[0], 'percent': int(value[3].rstrip('%'))}
    except (OSError, ValueError, subprocess.TimeoutExpired):
        pass
    try:
        owner = run(['gdbus','call','--session','--dest','org.freedesktop.DBus',
                     '--object-path','/org/freedesktop/DBus','--method',
                     'org.freedesktop.DBus.NameHasOwner','org.erikreider.swaync.cc'])
        if 'true' in owner:
            result['notifications'] = {
                'dnd': run(['swaync-client','-sw','-D']) == 'true',
                'count': int(run(['swaync-client','-sw','-c']))}
    except (OSError, ValueError, subprocess.TimeoutExpired):
        pass
    disk = shutil.disk_usage(Path.home())
    result['storage'] = {'used': disk.used, 'total': disk.total, 'free': disk.free}
    return result

def wallpaper_path(value):
    url = urlparse(value)
    if url.scheme not in ('', 'file') or url.netloc not in ('', 'localhost'):
        raise ValueError('Select a local image')
    path = Path(unquote(url.path)).expanduser().resolve()
    if not path.is_file() or path.suffix.lower() not in ('.png','.jpg','.jpeg','.webp','.bmp'):
        raise ValueError('Select PNG, JPEG, WebP or BMP')
    return path

def profile_picture(value):
    """Keep an immutable local copy; never alter or publish the chosen original."""
    path = wallpaper_path(value)
    limit = 16 * 1024 * 1024
    with path.open('rb') as source:
        data = source.read(limit + 1)
    if len(data) > limit:
        raise ValueError('Choose an image smaller than 16 MB')
    signatures = ((b'\x89PNG\r\n\x1a\n', '.png'), (b'\xff\xd8\xff', '.jpg'), (b'BM', '.bmp'))
    suffix = next((suffix for prefix, suffix in signatures if data.startswith(prefix)), None)
    if data[:4] == b'RIFF' and data[8:12] == b'WEBP':
        suffix = '.webp'
    if suffix is None:
        raise ValueError('Select a PNG, JPEG, WebP or BMP image')
    directory = paths()[0].parent / 'profile-pictures'
    directory.mkdir(parents=True, exist_ok=True)
    destination = directory / (hashlib.sha256(data).hexdigest() + suffix)
    if not destination.exists():
        temporary = destination.with_suffix('.tmp')
        with temporary.open('wb') as target:
            target.write(data)
        temporary.chmod(0o600)
        temporary.replace(destination)
    settings = preferences()
    settings['profilePicture'] = destination.as_uri()
    save(paths()[0], settings)

def hostname(value):
    if not re.fullmatch(r'[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?', value):
        raise ValueError('Use 1–63 lowercase letters, numbers or hyphens; no edge hyphens')
    # Existing system authorization is respected; no elevation or password handling.
    run(['hostnamectl', '--no-ask-password', '--static', 'hostname', value])

def action(name, value):
    if name == 'preference':
        key, enabled = value.split('=', 1)
        setting(key, enabled)
    elif name == 'brightness':
        number = float(value)
        if not math.isfinite(number) or not 1 <= number <= 100:
            raise ValueError('Brightness must be 1–100%')
        run(['brightnessctl','set',str(round(number))+'%'])
    elif name == 'wallpaper':
        path = wallpaper_path(value)
        run(['awww','img',str(path)])
        data = preferences()
        data['wallpaper'] = str(path)
        save(paths()[0], data)
    elif name == 'profile-picture':
        profile_picture(value)
    elif name == 'hostname':
        hostname(value)
    elif name == 'dnd' and value in ('true','false'):
        if status()['notifications'] is None:
            raise ValueError('Notification service unavailable')
        run(['swaync-client','-sw','-dn' if value=='true' else '-df'])
    elif name == 'notifications':
        if status()['notifications'] is None:
            raise ValueError('Notification service unavailable')
        run(['swaync-client','-sw','-op'])
    else:
        raise ValueError('Unknown action')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('operation', choices=['status','action','sample'])
    parser.add_argument('name', nargs='?', default='')
    parser.add_argument('value', nargs='?', default='')
    args = parser.parse_args()
    try:
        if args.operation == 'action':
            action(args.name, args.value)
        if args.operation == 'sample':
            usage(record=True)
        print(json.dumps({'ok':True, 'state':status()}))
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        print(json.dumps({'ok':False, 'error':str(error)[:240]}))

if __name__ == '__main__':
    # One shell has one backend, but serialize callbacks and atomic state writes.
    directory = paths()[0].parent
    directory.mkdir(parents=True, exist_ok=True)
    with (directory/'settings.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        main()
