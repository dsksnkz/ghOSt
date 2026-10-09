#!/usr/bin/env python3
"""Send real Qt events to isolated widgets, never to the user's desktop."""
import os
from pathlib import Path
import subprocess

environment = dict(os.environ, QT_QPA_PLATFORM="offscreen",
                   GHOST_CALENDAR_FIXTURE="1", GHOST_SETTINGS_FIXTURE="1")
environment.pop("WAYLAND_DISPLAY", None)
environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
entry = Path(__file__).resolve().parents[1] / "config/quickshell/ghost-bar/input-test.qml"
result = subprocess.run(["quickshell", "-p", str(entry)], env=environment,
                        capture_output=True, text=True, timeout=15, check=True)
output = result.stdout + result.stderr
for assertion in ("PASS: sidebar Escape event", "PASS: outside pointer event",
                  "PASS: per-output fullscreen visibility and restoration",
                  "PASS: Settings wheel propagation and Bezier selection movement",
                  "PASS: Settings fixed header, search, portrait, gear and all 14 pages",
                  "PASS: Settings live summaries, passive storage, all-page bounds and content scrolling",
                  "PASS: selected weather headline and temperature agree",
                  "PASS: expanded/compact music geometry and time formatting",
                  "PASS: click dispatches both fixed SFX and derived action"):
    assert assertion in output, output
print("PASS: Qt dismissal, fullscreen, Settings scroll/selection, weather and music layout")
