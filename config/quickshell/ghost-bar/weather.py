#!/usr/bin/env python3
"""Opt-in weather for ghOSt. No geolocation or access to another rice's settings."""
import json
import math
import os
from pathlib import Path
import urllib.parse
import urllib.request


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
    for date, code, value in zip(daily['time'], daily['weather_code'], daily['temperature_2m_max']):
        if finite(value):
            days.append({'date': date, 'condition': condition(code), 'temperature': value})
    return {'condition': condition(current['weather_code']), 'temperature': temperature, 'days': days[:5]}


def read_weather(config_path):
    if not config_path.is_file():
        return {'condition': 'unknown', 'days': [], 'error': 'Weather location not set'}
    try:
        config = json.loads(config_path.read_text())
        lat, lon = config['latitude'], config['longitude']
        if not finite(lat) or not finite(lon) or not -90 <= lat <= 90 or not -180 <= lon <= 180:
            raise ValueError('Invalid coordinates')
        query = urllib.parse.urlencode({'latitude': lat, 'longitude': lon,
            'current': 'temperature_2m,weather_code', 'daily': 'weather_code,temperature_2m_max',
            'past_days': 2, 'forecast_days': 3, 'timezone': 'auto'})
        request = urllib.request.Request('https://api.open-meteo.com/v1/forecast?' + query, headers={'User-Agent': 'ghOSt-weather/0.1'})
        with urllib.request.urlopen(request, timeout=5) as response:
            data = json.loads(response.read(500000))
        return normalize(data)
    except (OSError, ValueError, KeyError, TypeError):
        return {'condition': 'unknown', 'days': [], 'error': 'Weather unavailable'}


if __name__ == '__main__':
    root = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config')))
    print(json.dumps(read_weather(root / 'ghost/weather.json')))
