import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

spec = importlib.util.spec_from_file_location('weather', Path(__file__).parents[1] / 'config/quickshell/ghost-bar/weather.py')
weather = importlib.util.module_from_spec(spec)
spec.loader.exec_module(weather)


class Weather(unittest.TestCase):
    def test_today_matches_current_while_other_days_keep_daily_readings(self):
        data = {'current': {'time': '2026-10-07T20:00', 'temperature_2m': 12, 'weather_code': 0},
                'daily': {'time': ['2026-10-06', '2026-10-07', '2026-10-08'],
                          'weather_code': [3, 63, 63], 'temperature_2m_max': [21, 18, 15]}}
        result = weather.normalize(data)
        self.assertEqual(result['days'][1], {'date': '2026-10-07', 'condition': 'clear', 'temperature': 12})
        self.assertEqual(result['days'][0]['temperature'], 21)
        self.assertEqual(result['days'][2]['condition'], 'rain')

    def test_codes(self):
        for code, expected in [(0, 'clear'), (3, 'cloud'), (63, 'rain'), (75, 'snow'), (95, 'storm'), (123, 'unknown')]:
            self.assertEqual(weather.condition(code), expected)

    def test_normalize(self):
        data = {'current': {'temperature_2m': 15, 'weather_code': 95},
                'daily': {'time': ['2026-10-02', '2026-10-03'], 'weather_code': [95, 0], 'temperature_2m_max': [16, None]}}
        result = weather.normalize(data)
        self.assertEqual(result['condition'], 'storm')
        self.assertEqual(result['temperature'], 15)
        self.assertEqual(len(result['days']), 1)
        for invalid in [float('nan'), float('inf'), True, '15']:
            data['current']['temperature_2m'] = invalid
            with self.assertRaises(ValueError):
                weather.normalize(data)

    def test_unconfigured_never_calls_network(self):
        config = Mock()
        config.is_file.return_value = False
        with patch.object(weather.urllib.request, 'urlopen') as request:
            self.assertEqual(weather.read_weather(config)['condition'], 'unknown')
            request.assert_not_called()

    def test_invalid_coordinates_never_call_network(self):
        for lat, lon in [(91, 0), (0, -181), (True, 0), ('1', 0), (float('nan'), 0)]:
            config = Mock()
            config.read_text.return_value = json.dumps({'latitude': lat, 'longitude': lon})
            with patch.object(weather.urllib.request, 'urlopen') as request:
                self.assertEqual(weather.read_weather(config)['condition'], 'unknown')
                request.assert_not_called()

    def test_timeout_is_unavailable(self):
        config = Mock()
        config.read_text.return_value = '{"latitude":51,"longitude":0}'
        with patch.object(weather.urllib.request, 'urlopen', side_effect=TimeoutError) as request:
            self.assertEqual(weather.read_weather(config)['error'], 'Weather unavailable')
            self.assertEqual(request.call_args.kwargs['timeout'], 5)


class WeatherCache(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        root = Path(self.directory.name)
        self.config = root / 'config.json'
        self.config.write_text('{"latitude":51.5,"longitude":-0.1}')
        self.cache = root / 'cache/weather.json'
        self.data = {
            'timezone': 'Europe/London',
            'current': {'time': '2026-10-07T21:00', 'temperature_2m': 12, 'weather_code': 0},
            'daily': {'time': ['2026-10-07', '2026-10-08'],
                      'weather_code': [63, 3], 'temperature_2m_max': [18, 15]}}
        self.clock_patch = patch.object(weather.time, 'time', return_value=1791403200)
        self.clock = self.clock_patch.start()
        self.addCleanup(self.clock_patch.stop)
        self.network_patch = patch.object(weather.urllib.request, 'urlopen')
        self.request = self.network_patch.start()
        self.addCleanup(self.network_patch.stop)
        self.request.return_value.__enter__.return_value.read.return_value = json.dumps(self.data).encode()

    def read(self):
        return weather.read_weather(self.config, self.cache)

    def test_recent_observation_skips_network_and_keeps_today_synchronized(self):
        first = self.read()
        self.clock.return_value += 60
        self.assertEqual(self.read(), first)
        self.request.assert_called_once()
        self.assertEqual(first['days'][0]['temperature'], first['temperature'])
        self.assertEqual(self.cache.stat().st_mode & 0o777, 0o600)
        self.assertEqual(list(self.cache.parent.glob('*.tmp')), [])

    def test_expiry_refreshes_at_exact_fifteen_minute_boundary(self):
        self.read()
        self.clock.return_value += weather.CACHE_SECONDS
        self.read()
        self.assertEqual(self.request.call_count, 2)

    def test_changed_location_cannot_reuse_another_observation(self):
        self.read()
        self.config.write_text('{"latitude":52,"longitude":-0.1}')
        self.read()
        self.assertEqual(self.request.call_count, 2)

    def test_invalid_or_removed_location_cannot_use_cache(self):
        self.read()
        self.config.write_text('{"latitude":91,"longitude":0}')
        self.assertEqual(self.read()['condition'], 'unknown')
        self.config.unlink()
        self.assertEqual(self.read()['error'], 'Weather location not set')
        self.request.assert_called_once()

    def test_midnight_in_forecast_timezone_refreshes_even_inside_ttl(self):
        # London is UTC+1: these UTC timestamps cross local midnight, not UTC midnight.
        self.clock.return_value = 1791413880  #22:58 UTC,23:58 London
        self.read()
        self.clock.return_value += 240
        self.read()
        self.assertEqual(self.request.call_count, 2)

    def test_clock_rollback_rejects_future_cache(self):
        self.read()
        self.clock.return_value -= 1
        self.read()
        self.assertEqual(self.request.call_count, 2)

    def test_corrupt_cache_is_ignored(self):
        self.read()
        self.cache.write_text('not JSON')
        self.read()
        self.assertEqual(self.request.call_count, 2)

    def test_unrecognized_timezone_is_not_served_from_cache(self):
        self.read()
        cached = json.loads(self.cache.read_text())
        cached['data']['timezone'] = 'Missing/Timezone'
        self.cache.write_text(json.dumps(cached))
        self.read()
        self.assertEqual(self.request.call_count, 2)

    def test_expired_cache_is_not_presented_as_current_when_network_fails(self):
        self.read()
        self.clock.return_value += weather.CACHE_SECONDS
        self.request.side_effect = TimeoutError
        self.assertEqual(self.read()['error'], 'Weather unavailable')

    def test_cache_write_failure_keeps_successful_network_observation(self):
        blocker = Path(self.directory.name) / 'not-a-directory'
        blocker.write_text('preserve me')
        self.cache = blocker / 'weather.json'
        self.assertEqual(self.read()['temperature'], 12)
        self.assertEqual(blocker.read_text(), 'preserve me')


if __name__ == '__main__':
    unittest.main()
