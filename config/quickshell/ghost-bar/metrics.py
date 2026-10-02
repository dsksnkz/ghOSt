#!/usr/bin/env python3
"""Read-only telemetry stream. Runs only while the calendar is visible."""
import json
import math
from pathlib import Path
import subprocess
import sys
import time


def cpu_counters(text):
    fields = text.splitlines()[0].split()
    if not fields or fields[0] != 'cpu' or len(fields) < 5:
        raise ValueError('No aggregate CPU counters')
    # Linux guest counters are already included in user/nice; do not add them twice.
    values = [int(v) for v in fields[1:9]]
    return sum(values), values[3] + (values[4] if len(values) > 4 else 0)


def cpu_percent(before, after):
    total, idle = after[0] - before[0], after[1] - before[1]
    if total <= 0 or idle < 0 or idle > total:
        return None
    return round(100 * (total - idle) / total, 1)


def frequency(text):
    values = [float(line.split(':', 1)[1]) for line in text.splitlines()
              if line.startswith('cpu MHz')]
    return round(sum(values) / len(values)) if values else None


def gpu_percent():
    # NVIDIA is queried only for the selected GPU view. A missing device is unknown, not 0%.
    try:
        result = subprocess.run(
            ['nvidia-smi', '--query-gpu=utilization.gpu', '--format=csv,noheader,nounits', '--id=0'],
            capture_output=True, text=True, timeout=0.7, check=True)
        value = float(result.stdout.strip())
        if math.isfinite(value) and 0 <= value <= 100:
            return value
    except (OSError, ValueError, subprocess.SubprocessError):
        pass
    for path in sorted(Path('/sys/class/drm').glob('card[0-9]*/device/gpu_busy_percent')):
        try:
            value = float(path.read_text())
            if math.isfinite(value) and 0 <= value <= 100:
                return value
        except (OSError, ValueError):
            pass
    return None


def maximum_frequency():
    values = []
    for path in Path('/sys/devices/system/cpu').glob('cpu[0-9]*/cpufreq/cpuinfo_max_freq'):
        try:
            values.append(int(path.read_text()) / 1000)
        except (OSError, ValueError):
            pass
    return max(values) if values else None


def memory_percent(text):
    values = {line.split(':')[0]: int(line.split()[1]) for line in text.splitlines() if ':' in line}
    total, available = values.get('MemTotal', 0), values.get('MemAvailable')
    if total <= 0 or available is None or not 0 <= available <= total:
        return None
    return round(100 * (total - available) / total, 1)


def stream_all():
    previous = None
    ceiling = maximum_frequency()
    while True:
        started = time.monotonic()
        data = {'cpu': None, 'gpu': None, 'memory': None, 'processor': None, 'maximum': ceiling}
        try:
            current = cpu_counters(Path('/proc/stat').read_text())
            data['cpu'] = cpu_percent(previous, current) if previous else None
            previous = current
        except (OSError, ValueError):
            pass
        for key, read in [('memory', lambda: memory_percent(Path('/proc/meminfo').read_text())),
                          ('processor', lambda: frequency(Path('/proc/cpuinfo').read_text())), ('gpu', gpu_percent)]:
            try:
                data[key] = read()
            except (OSError, ValueError):
                pass
        print(json.dumps(data), flush=True)
        time.sleep(max(.05, 1 - (time.monotonic() - started)))


def stream(metric):
    previous = None
    ceiling = maximum_frequency()
    while True:
        started = time.monotonic()
        value = None
        try:
            if metric == 'cpu':
                current = cpu_counters(Path('/proc/stat').read_text())
                value = cpu_percent(previous, current) if previous else None
                previous = current
            elif metric == 'processor':
                value = frequency(Path('/proc/cpuinfo').read_text())
            else:
                value = gpu_percent()
        except (OSError, ValueError):
            pass
        print(json.dumps({'metric': metric, 'value': value,
                          'maximum': ceiling if metric == 'processor' else 100}), flush=True)
        time.sleep(max(0.05, 1 - (time.monotonic() - started)))


if __name__ == '__main__':
    metric = sys.argv[1] if len(sys.argv) == 2 else 'cpu'
    if metric not in ('cpu', 'gpu', 'processor', 'all'):
        raise SystemExit('Expected cpu, gpu, processor or all')
    try:
        stream_all() if metric == 'all' else stream(metric)
    except BrokenPipeError:
        pass
