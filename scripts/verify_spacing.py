#!/usr/bin/env python3
"""Inspect actual QML geometry without invoking system setters."""
import json
import os
import subprocess
import sys

environment = dict(os.environ)
environment.pop("WAYLAND_DISPLAY", None)
environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
output = subprocess.check_output(
    ["quickshell", "ipc", "-i", sys.argv[1], "call", "preview", "spacing"],
    env=environment,
    text=True,
)
state = json.loads(output)
assert state["rail"]["clockGap"] >= 16, state
assert abs(state["rail"]["clockInkCenter"] - state["rail"]["calendarIconCenter"]) < .01, state
assert abs(state["rail"]["batteryInkCenter"] - state["rail"]["batteryIconCenter"]) < .01, state
icons = state["rail"]["rightIcons"]
assert len(icons) == 5
assert all(icon["height"] == 22 for icon in icons)
assert max(icon["centerY"] for icon in icons) - min(icon["centerY"] for icon in icons) < 0.01
settings = state["settings"]
assert settings["rowHeight"] == 42 and settings["groupGap"] == 16
assert settings["rowGap"] == 6
assert settings["bodySpacing"] == 32 and settings["nameGap"] == 18
assert len(settings["icons"]) == 14
assert all(abs(icon["glyph"] / icon["well"] - 0.6) < 0.001 for icon in settings["icons"])
print("PASS: clock spacing, aligned22px rail icons,42px rows,60% glyphs,32px content gaps and18px pencil gap")
