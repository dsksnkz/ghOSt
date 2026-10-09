#!/usr/bin/env python3
"""ghOSt Settings: bounded standard-service queries and explicit user actions."""
import argparse
from datetime import datetime
import fcntl
import hashlib
import io
import json
import math
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import time
import wave
from urllib.parse import unquote, urlparse

SOUND_GROUPS = ('rail', 'sidebar', 'settings')
SOUND_PRESETS = (*SOUND_GROUPS, 'none', 'custom')
DEFAULTS = {'reducedMotion': False, 'usageTracking': False,
    'sounds': {'enabled': True, 'volume': 18,
               'presets': {group: group for group in SOUND_GROUPS}, 'files': {}},
    'widgets': {
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
    sounds = data.get('sounds', {})
    if isinstance(sounds, dict):
        if type(sounds.get('enabled')) is bool:
            result['sounds']['enabled'] = sounds['enabled']
        volume = sounds.get('volume')
        if type(volume) in (int, float) and math.isfinite(volume) and 0 <= volume <= 100:
            result['sounds']['volume'] = round(volume)
        for group in SOUND_GROUPS:
            preset = sounds.get('presets', {}).get(group) if isinstance(sounds.get('presets'), dict) else None
            if preset in SOUND_PRESETS:
                result['sounds']['presets'][group] = preset
            value = sounds.get('files', {}).get(group) if isinstance(sounds.get('files'), dict) else None
            # Only our immutable private copies are eligible, never remote audio.
            if isinstance(value, str):
                url = urlparse(value)
                path = Path(unquote(url.path))
                if (url.scheme == 'file' and not url.netloc
                        and path.parent == paths()[0].parent / 'ui-sounds'
                        and re.fullmatch(r'[a-f0-9]{64}\.wav', path.name)):
                    result['sounds']['files'][group] = value
    return result

def setting(key, value):
    data = preferences()
    if key == 'sounds.volume':
        number = float(value)
        if not math.isfinite(number) or not 0 <= number <= 100:
            raise ValueError('Click sound volume must be 0-100%')
        data['sounds']['volume'] = round(number)
    elif key.startswith('sounds.') and key[7:] in SOUND_GROUPS:
        group = key[7:]
        if value not in SOUND_PRESETS:
            raise ValueError('Unknown click sound')
        if value == 'custom' and group not in data['sounds']['files']:
            raise ValueError('Choose a WAV file first')
        data['sounds']['presets'][group] = value
    elif key in ('reducedMotion', 'usageTracking', 'sounds.enabled') or (key.startswith('widgets.') and key[8:] in DEFAULTS['widgets']):
        if value not in ('true', 'false'):
            raise ValueError('Expected true or false')
        if key == 'sounds.enabled':
            data['sounds']['enabled'] = value == 'true'
        elif key.startswith('widgets.'):
            data['widgets'][key[8:]] = value == 'true'
        else:
            data[key] = value == 'true'
    else:
        raise ValueError('Unknown setting')
    save(paths()[0], data)

def sound_file(group, value):
    """Validate a short PCM WAV and preserve its original in a private copy."""
    if group not in SOUND_GROUPS:
        raise ValueError('Unknown sound surface')
    url = urlparse(value)
    if url.scheme not in ('', 'file') or url.netloc not in ('', 'localhost'):
        raise ValueError('Select a local WAV file')
    path = Path(unquote(url.path)).expanduser().resolve()
    if not path.is_file() or path.suffix.lower() != '.wav':
        raise ValueError('Select a WAV file')
    with path.open('rb') as source:
        data = source.read(2 * 1024 * 1024 + 1)
    if len(data) > 2 * 1024 * 1024:
        raise ValueError('Choose a WAV smaller than 2 MB')
    try:
        with wave.open(io.BytesIO(data)) as audio:
            channels, width, rate, frames, compression, _ = audio.getparams()
            if (channels not in (1, 2) or width not in (1, 2)
                    or not 8000 <= rate <= 96000 or not 0 < frames <= 2 * rate
                    or compression != 'NONE'):
                raise ValueError('Use a PCM WAV, 8/16-bit mono/stereo, up to 2 seconds')
            if len(audio.readframes(frames)) != frames * channels * width:
                raise ValueError('The WAV file is incomplete')
    except (wave.Error, EOFError) as error:
        raise ValueError('Use an uncompressed PCM WAV file') from error
    directory = paths()[0].parent / 'ui-sounds'
    directory.mkdir(parents=True, exist_ok=True)
    destination = directory / (hashlib.sha256(data).hexdigest() + '.wav')
    if not destination.exists():
        temporary = destination.with_suffix('.tmp')
        temporary.write_bytes(data)
        temporary.chmod(0o600)
        temporary.replace(destination)
    preferences_data = preferences()
    preferences_data['sounds']['files'][group] = destination.as_uri()
    preferences_data['sounds']['presets'][group] = 'custom'
    save(paths()[0], preferences_data)

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
    elif name == 'sound-file':
        group, filename = value.split('=', 1)
        sound_file(group, filename)
    elif name == 'hostname':
        hostname(value)
    elif name in ('dnd','notifications'):
        raise ValueError('Use the ghOSt notification controls')
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
