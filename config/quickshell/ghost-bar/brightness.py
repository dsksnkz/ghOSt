#!/usr/bin/env python3
"""Reads and sets one output's brightness: backlight on a laptop panel, DDC/CI on a monitor."""
import json
import os
import re
import subprocess
import sys
import time

CACHE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "ghost-ddc-displays.json")


def run(*command):
    return subprocess.run(command, capture_output=True, text=True, timeout=30, check=True).stdout


# A monitor stays busy for a moment after a command and refuses the next one.
def ddc(*command):
    for attempt in range(4):
        try:
            return run("ddcutil", *command)
        except subprocess.CalledProcessError:
            if attempt == 3:
                raise
            time.sleep(0.5)


def detect_bus(connector):
    bus = None
    for line in run("ddcutil", "detect").splitlines():
        found = re.search(r"/dev/i2c-(\d+)", line)
        if found:
            bus = found.group(1)
        elif "DRM_connector" in line and line.strip().endswith("-" + connector):
            return bus
    return None


def read_cache():
    try:
        with open(CACHE) as file:
            return json.load(file)
    except (OSError, ValueError):
        return {}


# Detection takes seconds and buses can change, so it runs once and again after a failure.
def with_bus(connector, action):
    cache = read_cache()
    if connector in cache:
        try:
            return action(cache[connector])
        except subprocess.SubprocessError:
            pass
    bus = detect_bus(connector)
    if bus is None:
        raise LookupError(connector)
    cache[connector] = bus
    with open(CACHE, "w") as file:
        json.dump(cache, file)
    return action(bus)


def read_vcp(bus):
    # Brief output: VCP 10 C <current> <maximum>
    _, _, _, current, maximum = ddc("--bus", bus, "--brief", "getvcp", "10").split()
    return int(current), int(maximum)


def get(connector):
    if connector.startswith("eDP-"):
        return int(run("brightnessctl", "-m").split(",")[3].rstrip("%"))
    current, maximum = with_bus(connector, read_vcp)
    return round(current * 100 / maximum)


def set_brightness(connector, percent):
    if connector.startswith("eDP-"):
        run("brightnessctl", "set", f"{percent}%")
        return

    def write(bus):
        _, maximum = read_vcp(bus)
        ddc("--bus", bus, "--noverify", "setvcp", "10", str(round(percent * maximum / 100)))

    with_bus(connector, write)


if __name__ == "__main__":
    try:
        if sys.argv[1] == "get":
            print(get(sys.argv[2]))
        else:
            set_brightness(sys.argv[2], max(0, min(100, int(sys.argv[3]))))
    except (OSError, LookupError, ValueError, subprocess.SubprocessError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
