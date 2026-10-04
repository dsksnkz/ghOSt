#!/usr/bin/env python3
"""Inspect actual fixture pixels, not merely QML radius-property values."""
from pathlib import Path
import sys
from PIL import Image

root = Path(sys.argv[1])
with Image.open(root / "sidebar-frame.png") as source:
    image = source.convert("RGB")
    assert image.getpixel((31, 269)) == (24, 24, 24), "15px WLAN housing corner remains too square"
    assert image.getpixel((192, 269)) == (24, 24, 24), "15px Bluetooth housing corner remains too square"
    assert image.getpixel((50, 270)) != (21, 21, 21), "WLAN cap failed to paint"
    assert image.getpixel((30, 524)) != (21, 21, 21), "Slider fill lost its straight side"
with Image.open(root / "settings-general.png") as source:
    image = source.convert("RGB")
    assert image.getpixel((1113, 269)) == (37, 37, 37), "21px portrait clipping remains too square"
    assert image.getpixel((1167, 323)) != (37, 37, 37), "Portrait failed to paint"
    assert image.getpixel((525, 213)) == (21, 21, 21), "10px Settings frame corner failed"
print("PASS: actual WLAN/Bluetooth15px corners, slider fill, portrait21px clipping and Settings frame10px pixels")
