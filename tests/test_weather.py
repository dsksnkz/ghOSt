import importlib.util
import json
from pathlib import Path
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


if __name__ == '__main__':
    unittest.main()
