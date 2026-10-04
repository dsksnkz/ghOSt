#!/usr/bin/env python3
"""Export only allowlisted sample-data captures, never native desktop captures."""
from pathlib import Path
import sys
from PIL import Image

captures = Path(sys.argv[1]).resolve()
assets = Path(__file__).resolve().parents[1] / "site/assets"
pages = ("general", "sound", "battery", "widgets", "brightness", "wallpaper",
         "notifications", "network", "bluetooth", "airplane", "accessibility",
         "storage", "applications", "about", "portrait-fixture", "name-editor",
         "search-sound")
for page in pages:
    name = "settings-" + page
    with Image.open(captures / (name + ".png")) as source:
        source.crop((488, 176, 1588, 936)).convert("RGB").save(
            assets / (name + ".webp"), quality=92)
for name in ("rail-frame", "sidebar-frame", "calendar-frame", "desktop-frame",
             "power-frame", "notification-popup"):
    with Image.open(captures / (name + ".png")) as source:
        source.convert("RGB").save(assets / (name + ".webp"), quality=92)
print("Exported17 Settings and6 sample-data surface screenshots")
if len(sys.argv) > 2:
    # The caller first resolves this path from the running wallpaper service.
    with Image.open(Path(sys.argv[2])) as wallpaper:
        wallpaper.convert("RGB").resize((1920, 1080), Image.Resampling.LANCZOS).save(
            assets / "wallpaper.webp", quality=90)
    print("Exported separate wallpaper copy without private image metadata")
