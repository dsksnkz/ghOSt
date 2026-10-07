#!/usr/bin/env python3
"""Opt-in weather for ghOSt. No geolocation or access to another rice's settings."""
import json
import math
import os
from datetime import datetime
from pathlib import Path
import tempfile
import time
import urllib.parse
import urllib.request
from zoneinfo import ZoneInfo


CACHE_SECONDS = 15 * 60
MAX_RESPONSE_BYTES = 500000


def condition(code):
    if code == 0:
        return 'clear'
    if code in (1, 2, 3, 45, 48):
        return 'cloud'
    if code in (51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82):
        return 'rain'
    if code in (71, 73, 75, 77, 85, 86):
        return 'snow'
    if code in (95, 96, 99):
        return 'storm'
    return 'unknown'


def finite(value):
    return type(value) in (int, float) and math.isfinite(value)


def normalize(data):
    current, daily = data['current'], data['daily']
    temperature = current['temperature_2m']
    if not finite(temperature):
        raise ValueError('Invalid temperature')
    days = []
    current_date = current.get('time', '').split('T')[0]
    for date, code, value in zip(daily['time'], daily['weather_code'], daily['temperature_2m_max']):
        if finite(value):
            # Today describes now, like the headline, not the daily maximum
            # or dominant weather code. Other days retain their daily readings.
            is_today = date == current_date
            days.append({'date': date,
                         'condition': condition(current['weather_code'] if is_today else code),
                         'temperature': temperature if is_today else value})
    return {'condition': condition(current['weather_code']), 'temperature': temperature, 'days': days[:5]}


def cached_weather(path, coordinates, now):
    """Reuse a recent observation, never another location or yesterday's day list."""
    if path is None:
        return None
    try:
        if path.stat().st_size > MAX_RESPONSE_BYTES + 1000:
            return None
        cached = json.loads(path.read_text())
        fetched = cached['fetchedAt']
        if cached['coordinates'] != coordinates or not finite(fetched):
            return None
        if not 0 <= now - fetched < CACHE_SECONDS:
            return None
        timezone = ZoneInfo(cached['data']['timezone'])
        if datetime.fromtimestamp(now, timezone).date() != datetime.fromtimestamp(fetched, timezone).date():
            return None
        return normalize(cached['data'])
    except (OSError, ValueError, KeyError, TypeError, OverflowError):
        return None


def cache_weather(path, coordinates, data, now):
    """A cache-write failure cannot discard an otherwise successful observation."""
    if path is None:
        return
    temporary = None
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, prefix='.weather-',
                                         suffix='.tmp', delete=False) as output:
            temporary = Path(output.name)
            json.dump({'coordinates': coordinates, 'fetchedAt': now, 'data': data}, output)
        # NamedTemporaryFile creates a private 0600 file; replace is atomic so
        # multiple display readers never see a partially written observation.
        temporary.replace(path)
    except OSError:
        pass
    finally:
        if temporary is not None:
            try:
                temporary.unlink(missing_ok=True)
            except OSError:
                pass


def read_weather(config_path, cache_path=None):
    if not config_path.is_file():
        return {'condition': 'unknown', 'days': [], 'error': 'Weather location not set'}
    try:
        config = json.loads(config_path.read_text())
        lat, lon = config['latitude'], config['longitude']
        if not finite(lat) or not finite(lon) or not -90 <= lat <= 90 or not -180 <= lon <= 180:
            raise ValueError('Invalid coordinates')
        coordinates = [lat, lon]
        cached = cached_weather(cache_path, coordinates, time.time())
        if cached is not None:
            return cached
        query = urllib.parse.urlencode({'latitude': lat, 'longitude': lon,
            'current': 'temperature_2m,weather_code', 'daily': 'weather_code,temperature_2m_max',
            'past_days': 2, 'forecast_days': 3, 'timezone': 'auto'})
        request = urllib.request.Request('https://api.open-meteo.com/v1/forecast?' + query, headers={'User-Agent': 'ghOSt-weather/0.1'})
        with urllib.request.urlopen(request, timeout=5) as response:
            data = json.loads(response.read(MAX_RESPONSE_BYTES))
        result = normalize(data)
        cache_weather(cache_path, coordinates, data, time.time())
        return result
    except (OSError, ValueError, KeyError, TypeError):
        return {'condition': 'unknown', 'days': [], 'error': 'Weather unavailable'}


if __name__ == '__main__':
    root = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config')))
    cache = Path(os.environ.get('XDG_CACHE_HOME', str(Path.home() / '.cache')))
    print(json.dumps(read_weather(root / 'ghost/weather.json', cache / 'ghost/weather.json')))
