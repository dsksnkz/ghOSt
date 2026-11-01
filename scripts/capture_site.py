#!/usr/bin/env python3
"""Render the website images from real ghOSt components with sample data.

Uses a private copy of the shell under .local/site-capture and the real GPU, because
blur and clipping need shaders. A small window shows for about 20 seconds. No system
state, media, window contents or personal files are read.
"""
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / ".local/site-capture"
SITE = ROOT / "site/assets/product"
SAMPLE = ('({identity: "Player", trackTitle: "Open Water", trackArtist: "Sample Artist", '
          'trackArtUrl: Qt.resolvedUrl("sample-art.png"), length: 243, position: 88, canSeek: true, '
          'canGoPrevious: true, canGoNext: true, canTogglePlaying: true, shuffleSupported: true, '
          'shuffle: true, loopSupported: true, loopState: 0})')
LEVELS = "[.28,.46,.82,.58,.74,.4,.66,.8,.5,.56,.9,.42,.68,.3,.48]"


def noise(width, height, seed, octaves=6, stretch=4.0):
    """Layered value noise, stretched sideways so it reads as water."""
    random = np.random.default_rng(seed)
    result = np.zeros((height, width), dtype=np.float32)
    amplitude, total = 1.0, 0.0
    for octave in range(octaves):
        rows, columns = 3 * 2 ** octave, max(3, int(3 * 2 ** octave / stretch))
        grid = random.random((rows + 2, columns + 2)).astype(np.float32)
        y = np.linspace(0, rows, height, endpoint=False)
        x = np.linspace(0, columns, width, endpoint=False)
        y0, x0 = y.astype(int), x.astype(int)
        fy = (y - y0)[:, None]
        fx = (x - x0)[None, :]
        fy, fx = fy * fy * (3 - 2 * fy), fx * fx * (3 - 2 * fx)
        a = grid[np.ix_(y0, x0)] * (1 - fx) + grid[np.ix_(y0, x0 + 1)] * fx
        b = grid[np.ix_(y0 + 1, x0)] * (1 - fx) + grid[np.ix_(y0 + 1, x0 + 1)] * fx
        result += (a * (1 - fy) + b * fy) * amplitude
        total += amplitude
        amplitude *= .55
    return result / total


def wallpaper(path, width=3840, height=2160):
    """An original dark texture, so the site ships no third-party artwork."""
    w, h = width // 4, height // 4
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    # Long diagonal folds of light that fade toward the bottom corner.
    drift = noise(w, h, 21, octaves=2, stretch=1.5)
    u = (x / w * .8 + y / h * .55) + drift * .5
    folds = (.5 + .5 * np.sin(u * 2 * np.pi * 1.7)) ** 3
    glow = np.exp(-(((x - w * .7) / (w * .75)) ** 2 + ((y - h * .1) / (h * .85)) ** 2))
    grey = np.clip(.02 + folds * glow * .17 + glow * .02, 0, 1)
    raw = path.with_suffix(".gray")
    (grey * 255).astype(np.uint8).tofile(raw)
    subprocess.run(["magick", "-size", f"{w}x{h}", "-depth", "8", f"gray:{raw}", "-resize", f"{width}x{height}!",
                    "-blur", "0x14", "-attenuate", ".12", "+noise", "Gaussian", "-colorspace", "Gray", str(path)], check=True)
    raw.unlink()


def magick(*arguments):
    subprocess.run(["magick", *map(str, arguments)], check=True)


def prepare():
    if WORK.exists():
        shutil.rmtree(WORK)
    runtime = WORK / "runtime"
    shutil.copytree(ROOT / "config/quickshell/ghost-bar", runtime, ignore=shutil.ignore_patterns("__pycache__"))
    shutil.copy2(Path(__file__).with_name("site-capture.qml"), runtime / "site-capture.qml")
    (runtime / "frames").mkdir()
    for name in ("MediaPanel.qml", "MusicBar.qml"):
        path = runtime / name
        text = path.read_text()
        for old, new in (("readonly property var player: Desk.player", "readonly property var player: " + SAMPLE),
                         ("readonly property bool playing: Desk.playing", "readonly property bool playing: true")):
            if old not in text:
                raise RuntimeError(name + " changed: review the sample-data adapter")
            text = text.replace(old, new)
        path.write_text(text)
    path = runtime / "AudioSpectrum.qml"
    path.write_text(path.read_text().replace("property var levels: Array(barCount).fill(0)", "property var levels: " + LEVELS))
    path = runtime / "SwitcherScene.qml"
    text = path.read_text()
    for old, new in (('readonly property string wallpaper: previewMode ? "" :', 'readonly property string wallpaper: previewMode ? Qt.resolvedUrl("frames/wallpaper.png") :'),
                     ("windows: scene.windowsFor(card.modelData)", 'windows: []\n                    sampleFrame: Qt.resolvedUrl("frames/" + card.modelData + ".png")'),
                     ("windows: scene.windowsFor(magicCard.modelData.key)", 'windows: []\n                        sampleFrame: Qt.resolvedUrl("frames/" + magicCard.modelData.special + ".png")')):
        if old not in text:
            raise RuntimeError("SwitcherScene changed: review the sample-data adapter")
        text = text.replace(old, new)
    path.write_text(text)
    path = runtime / "SwitcherPreview.qml"
    text = path.read_text()
    old = "        Item {\n            width: preview.logicalWidth"
    if old not in text:
        raise RuntimeError("SwitcherPreview changed: review the sample-data adapter")
    path.write_text(text.replace("    property real resolution: 1\n", '    property real resolution: 1\n    property url sampleFrame\n').replace(
        old, "        Image {\n            anchors.fill: parent\n            source: preview.sampleFrame\n        }\n" + old))
    entries = WORK / "apps/applications"
    entries.mkdir(parents=True)
    for name, icon in (("Files", "folder"), ("Terminal", "terminal"), ("Browser", "app"), ("Music", "volume")):
        (entries / (name.lower() + ".desktop")).write_text(
            f"[Desktop Entry]\nType=Application\nName={name}\nExec=true\nIcon={runtime}/icons/white/{icon}.svg\n")
    return runtime


def render(runtime, scenes):
    environment = dict(os.environ, GHOST_CALENDAR_FIXTURE="1", GHOST_SETTINGS_FIXTURE="1",
                       DBUS_SESSION_BUS_ADDRESS="unix:path=/nonexistent-ghost-site-bus")
    environment.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
    # Only the sample applications below, never this machine's apps or pins.
    environment.update(XDG_DATA_DIRS=str(WORK / "apps"), XDG_DATA_HOME=str(WORK / "data"),
                       XDG_CONFIG_HOME=str(WORK / "config"), XDG_STATE_HOME=str(WORK / "state"),
                       XDG_CACHE_HOME=str(WORK / "cache"))
    log_path = WORK / "renderer.log"
    with log_path.open("w") as log:
        process = subprocess.Popen(["quickshell", "-p", str(runtime / "site-capture.qml")], env=environment, stdout=log, stderr=log)
        try:
            deadline = time.monotonic() + 20
            instance = None
            while time.monotonic() < deadline and not instance:
                content = log_path.read_text()
                match = re.search(r"by-id/([^/]+)/log", content)
                if match and "Configuration Loaded" in content:
                    instance = match.group(1)
                time.sleep(.1)
            if not instance:
                raise RuntimeError(log_path.read_text())
            for scene in scenes:
                path = WORK / (scene + ".png")
                path.unlink(missing_ok=True)
                subprocess.run(["quickshell", "ipc", "-i", instance, "call", "site", "frame", scene, str(path)],
                               env=environment, check=True, capture_output=True, timeout=5)
                deadline = time.monotonic() + 8
                while not path.exists():
                    if time.monotonic() > deadline:
                        raise RuntimeError("Frame not written: " + scene)
                    time.sleep(.02)
                time.sleep(.2)
            subprocess.run(["quickshell", "ipc", "-i", instance, "call", "site", "stop"], env=environment, capture_output=True, timeout=5)
        finally:
            try:
                process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                process.terminate()


def main():
    runtime = prepare()
    desk = WORK / "wallpaper.png"
    wallpaper(desk)
    magick(desk, "-resize", "1920x1080", runtime / "frames/wallpaper.png")
    art = runtime / "sample-art.png"
    magick(desk, "-crop", "1200x1200+1300+200", "+repage", "-resize", "528x528", "-brightness-contrast", "18x20", art)
    render(runtime, ("rail", "calendar", "media", "sidebar", "settings", "launcher"))

    # Sample windows for the switcher cards: real panels placed on empty desktops.
    blank = ("-size", "1920x1080", "xc:none")
    magick(*blank, "(", WORK / "settings.png", "-resize", "1500x", ")", "-gravity", "center", "-composite", runtime / "frames/1.png")
    magick(*blank, "(", WORK / "calendar.png", "-resize", "1400x", ")", "-gravity", "center", "-composite", runtime / "frames/2.png")
    magick(*blank, "(", WORK / "launcher.png", "-resize", "1000x", ")", "-gravity", "center", "-composite", runtime / "frames/5.png")
    magick(*blank, "(", WORK / "media.png", "-resize", "900x", ")", "-gravity", "center", "-composite", runtime / "frames/music.png")
    magick(*blank, "(", WORK / "sidebar.png", "-resize", "x1000", ")", "-gravity", "east", "-geometry", "+24+0", "-composite", runtime / "frames/ai.png")
    for name in (3, 4):
        magick(*blank, runtime / f"frames/{name}.png")
    render(runtime, ("switcher",))

    SITE.mkdir(parents=True, exist_ok=True)
    webp = lambda *arguments, name, quality=86: magick(*arguments, "-quality", quality, "-define", "webp:method=6", SITE / (name + ".webp"))
    # The desktop: the rail across the top with the calendar open beneath the clock.
    margin = round((3840 - int(subprocess.check_output(["magick", "identify", "-format", "%w", WORK / "calendar.png"]))) / 2)
    webp(desk, WORK / "rail.png", "-gravity", "north", "-composite", WORK / "calendar.png", "-gravity", "northwest",
         "-geometry", f"+{margin}+136", "-composite", "-resize", "2880x", name="desktop")
    webp(WORK / "rail.png", name="rail")
    webp(WORK / "rail.png", "-crop", "900x70+0+0", "+repage", name="rail-left")
    webp(WORK / "rail.png", "-gravity", "east", "-crop", "560x70+0+0", "+repage", name="rail-right")
    webp(WORK / "switcher.png", "-resize", "2880x", name="switcher")
    for name in ("calendar", "media", "launcher", "sidebar", "settings"):
        webp(WORK / (name + ".png"), name=name)
    # The login theme, with the sample cover standing in for a profile picture.
    login = WORK / "login.png"
    subprocess.run(["python3", str(ROOT / "scripts/verify_sddm_theme.py"), str(login)], check=True, capture_output=True,
                   env=dict(os.environ, GHOST_SDDM_CAPTURE_SCALE="2", GHOST_SDDM_ICON=str(art)))
    webp(login, "-resize", "2880x", name="login")


if __name__ == "__main__":
    main()
