#!/usr/bin/env python3
"""Verify the media popup offscreen with a sample player; no MPRIS or desktop access."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
SAMPLE = ('({identity: "Player", trackTitle: "Midnight City", trackArtist: "M83", trackArtUrl: Qt.resolvedUrl("sample-art.png"), '
          'length: 243, position: 88, canSeek: true, canGoPrevious: true, canGoNext: true, canTogglePlaying: true, '
          'shuffleSupported: true, shuffle: false, loopSupported: true, loopState: 0, calls: [], '
          'previous() { this.calls.push("previous"); }, next() { this.calls.push("next"); }, '
          'togglePlaying() { this.calls.push("toggle"); }})')
environment = dict(os.environ, QT_QPA_PLATFORM="offscreen", GHOST_SETTINGS_FIXTURE="1",
                   DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent-ghost-test-bus")
environment.pop("WAYLAND_DISPLAY", None)
environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
if len(sys.argv) > 1:
    captures = Path(sys.argv[1]).resolve()
    captures.mkdir(parents=True, exist_ok=True)
    environment["GHOST_MEDIA_CAPTURE_DIR"] = str(captures)
with tempfile.TemporaryDirectory(prefix="ghost-media-") as directory:
    runtime = Path(directory) / "runtime"
    shutil.copytree(root / "config/quickshell/ghost-bar", runtime)
    panel = runtime / "MediaPanel.qml"
    text = panel.read_text()
    for old, new in (("readonly property var player: Desk.player", "readonly property var player: " + SAMPLE),
                     ("readonly property bool playing: Desk.playing", "readonly property bool playing: true")):
        assert old in text, old
        text = text.replace(old, new)
    panel.write_text(text)
    subprocess.run(["magick", "-size", "400x400", "gradient:#30343a-#0a0a0a", str(runtime / "sample-art.png")], check=True)
    entry = runtime / "media-panel-test.qml"
    shutil.copyfile(root / "tests/media-panel.qml", entry)
    result = subprocess.run(["quickshell", "-p", str(entry)], env=environment,
                            capture_output=True, text=True, timeout=20)
output = result.stdout + result.stderr
assert result.returncode == 0, output
assert "PASS: media panel track" in output, output
assert not any(error in output for error in ("FAIL!", "ReferenceError", "TypeError", "Binding loop")), output
print("PASS: media panel layout and controls")
