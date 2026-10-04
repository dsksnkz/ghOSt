#!/usr/bin/env python3
"""Capture corrected surfaces from the isolated sample-data entry only."""
import os
from pathlib import Path
import subprocess
import sys
import time

instance, output = sys.argv[1], Path(sys.argv[2]).resolve()
output.mkdir(parents=True, exist_ok=True)
environment = dict(os.environ)
environment.pop("WAYLAND_DISPLAY", None)
environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)

def call(*values):
    return subprocess.check_output(["quickshell", "ipc", "-i", instance,
                                   "call", "preview", *values], env=environment,
                                   text=True)

def capture(name):
    path = output / (name + ".png")
    previous = path.stat().st_mtime_ns if path.exists() else 0
    call("capture", str(path))
    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        if path.exists() and path.stat().st_mtime_ns > previous:
            return
        time.sleep(.05)
    raise AssertionError("Capture missing: " + name)

call("calendar", "reduced", "true")
call("notifications", "clear")
for page in ("rail", "sidebar", "calendar", "desktop", "session"):
    call("page", page)
    time.sleep(.1)
    capture(("power" if page == "session" else page) + "-frame")
call("page", "rail")
call("notifications", "popup")
time.sleep(.1)
capture("notification-popup")
call("notifications", "clear")
print("PASS: rail, empty sidebar, calendar, composition and notification popup captures")
