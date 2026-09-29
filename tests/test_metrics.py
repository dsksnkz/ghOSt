import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch
import subprocess

spec = importlib.util.spec_from_file_location('metrics', Path(__file__).parents[1] / 'config/quickshell/ghost-bar/metrics.py')
metrics = importlib.util.module_from_spec(spec)
spec.loader.exec_module(metrics)


class Telemetry(unittest.TestCase):
    def test_guest_is_not_counted_twice(self):
        self.assertEqual(metrics.cpu_counters('cpu 10 2 3 80 5 0 0 0 7 1\ncpu0 0'), (100, 85))

    def test_utilization_uses_counter_delta(self):
        self.assertEqual(metrics.cpu_percent((100, 85), (200, 110)), 75)
        self.assertEqual(metrics.cpu_percent((100, 85), (200, 185)), 0)

    def test_reset_or_bad_counters_are_unknown(self):
        for after in [(100, 85), (99, 85), (200, 84), (200, 300)]:
            self.assertIsNone(metrics.cpu_percent((100, 85), after))

    def test_average_clock(self):
        self.assertEqual(metrics.frequency('cpu MHz : 1000\ncpu MHz : 3000\n'), 2000)
        self.assertIsNone(metrics.frequency('processor : 0'))

    def test_missing_gpu_is_unknown(self):
        with patch.object(metrics.subprocess, 'run', side_effect=FileNotFoundError), patch.object(metrics.Path, 'glob', return_value=[]):
            self.assertIsNone(metrics.gpu_percent())

    def test_gpu_timeout_and_real_zero(self):
        with patch.object(metrics.subprocess, 'run', side_effect=subprocess.TimeoutExpired('nvidia-smi', .7)), patch.object(metrics.Path, 'glob', return_value=[]):
            self.assertIsNone(metrics.gpu_percent())
        with patch.object(metrics.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, '0\n')):
            self.assertEqual(metrics.gpu_percent(), 0)


if __name__ == '__main__':
    unittest.main()
