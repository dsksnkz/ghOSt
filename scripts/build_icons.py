#!/usr/bin/env python3
"""Build offline SVG exports from vendored Google Material Symbols Outlined."""
import argparse
from hashlib import sha256
from html import escape
import json
from pathlib import Path
import urllib.request
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/material-symbols"
DESTINATIONS = (ROOT / "config/quickshell/ghost-bar/icons", ROOT / "site/assets/icons")
REVISION = "10ecc14790612ca8fd164e3f4ffe9c16fc50d5b7"
# Stable ghOSt IDs preserve every existing control and saved preference.
MAPPING = {
    "settings": "settings", "wifi": "wifi", "network": "lan",
    "ethernet": "settings_ethernet", "bluetooth": "bluetooth",
    "display": "desktop_windows", "brightness": "light_mode",
    "volume": "volume_up", "mute": "volume_off", "microphone": "mic",
    "notifications": "notifications", "appearance": "contrast",
    "wallpaper": "wallpaper", "keyboard": "keyboard", "mouse": "mouse",
    "touchpad": "touchpad_mouse", "accessibility": "accessibility_new",
    "language": "translate", "calendar": "calendar_month", "clock": "schedule",
    "battery": "battery_full", "power": "power_settings_new", "storage": "hard_drive",
    "app": "apps", "accounts": "person", "privacy": "visibility",
    "security": "verified_user", "lock": "lock", "updates": "sync",
    "info": "info", "search": "search", "edit": "edit", "close": "close",
    "check": "check", "plus": "add", "minus": "remove", "back": "chevron_left",
    "forward": "chevron_right", "up": "keyboard_arrow_up",
    "workspace-indicator": "arrow_drop_up", "down": "keyboard_arrow_down",
    "menu": "menu", "pin": "push_pin", "folder": "folder",
    "folder-rounded": "folder", "terminal": "terminal", "browser": "language",
    "cpu": "memory", "gpu": "developer_board", "memory": "memory_alt",
    "play": "play_arrow", "pause": "pause", "previous": "skip_previous",
    "next": "skip_next", "logout": "logout", "restart": "restart_alt",
    "sleep": "bedtime", "cloud": "cloud", "rain": "rainy",
    "storm": "thunderstorm", "lightning": "bolt", "snow": "ac_unit",
    "dot": "fiber_manual_record",
}
WEATHER = ("cloud", "brightness", "rain", "snow", "lightning", "storm")


def fetch_sources():
    """Explicit developer operation only; normal builds never access the network."""
    SOURCE.mkdir(parents=True, exist_ok=True)
    records = {}
    for name in sorted(set(MAPPING.values())):
        url = (f"https://raw.githubusercontent.com/google/material-design-icons/{REVISION}"
               f"/symbols/web/{name}/materialsymbolsoutlined/{name}_24px.svg")
        data = urllib.request.urlopen(url, timeout=30).read()
        ET.fromstring(data)
        filename = name + ".svg"
        (SOURCE / filename).write_bytes(data)
        records[filename] = {"url": url, "sha256": sha256(data).hexdigest()}
    for name in WEATHER:
        url = ("https://fonts.gstatic.com/s/i/short-term/release/materialsymbolsoutlined/"
               f"{MAPPING[name]}/wght200/24px.svg")
        data = urllib.request.urlopen(url, timeout=30).read()
        ET.fromstring(data)
        filename = "weather-" + name + ".svg"
        (SOURCE / filename).write_bytes(data)
        records[filename] = {"url": url, "sha256": sha256(data).hexdigest()}
    license_url = f"https://raw.githubusercontent.com/google/material-design-icons/{REVISION}/LICENSE"
    (SOURCE / "LICENSE").write_bytes(urllib.request.urlopen(license_url, timeout=30).read())
    (SOURCE / "sources.json").write_text(json.dumps(records, indent=2) + "\n")


def geometry(filename):
    data = (SOURCE / filename).read_bytes()
    records = json.loads((SOURCE / "sources.json").read_text())
    if sha256(data).hexdigest() != records[filename]["sha256"]:
        raise ValueError(f"Material source checksum mismatch: {filename}")
    root = ET.fromstring(data)
    # Most sources use 960 units; a few official files still use 24 units.
    # One logical pixel of safe raster margin avoids clipping the widest symbols.
    x, y, width, height = map(float, root.get('viewBox', '0 0 24 24').split())
    scale = 22 / max(width, height)
    tx = 12 - (x + width / 2) * scale
    ty = 12 - (y + height / 2) * scale
    paths = ''.join(f'<path d="{escape(p.attrib["d"], quote=True)}"/>' for p in root)
    return f'<g transform="translate({tx:g} {ty:g}) scale({scale:.12g})" fill="currentColor">{paths}</g>'


def svg(name, body, color):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
            f'viewBox="0 0 24 24" fill="none" color="{color}">'
            f'<title>{escape(name)}</title>{body}</svg>\n')


def build(check=False):
    catalogue = json.loads((SOURCE / "catalogue.json").read_text())
    icons = {name: geometry(symbol + ".svg") for name, symbol in MAPPING.items()}
    # A wordmark is branding, not a generic system-control icon.
    brand = ET.parse(SOURCE / "ghost-brand.svg").getroot()
    ET.register_namespace('', 'http://www.w3.org/2000/svg')
    icons["ghost"] = ''.join(ET.tostring(e, encoding="unicode") for e in brand
                             if e.tag.split('}')[-1] != 'title')
    variants = {"weather-" + name: geometry("weather-" + name + ".svg") for name in WEATHER}
    files = {}
    for directory in DESTINATIONS:
        files[directory / "LICENSE-Material-Symbols.txt"] = (SOURCE / "LICENSE").read_text()
        files[directory / "NOTICE.txt"] = (
            "Google Material Symbols Outlined - Google, Apache License 2.0.\n"
            "https://github.com/google/material-design-icons\n"
            f"Control sources pinned to {REVISION}; weather sources from Google Fonts.\n"
            "Modified for ghOSt: normalized SVG bounds and monochrome color.\n"
            "ghost.svg is the separate Turret Road G brand outline, under its bundled OFL.\n")
        for name, body in {**icons, **variants}.items():
            for tone, color in (("black", "#000000"), ("white", "#ffffff")):
                files[directory / tone / f"{name}.svg"] = svg(name, body, color)
        files[directory / "manifest.json"] = json.dumps(catalogue, indent=2) + "\n"
    files[ROOT / "config/quickshell/ghost-bar/IconCatalogue.js"] = (
        "// Generated by scripts/build_icons.py\nvar names = "
        + json.dumps([i["name"] for i in catalogue]) + ";\n")
    tiles = []
    for index, icon in enumerate(catalogue):
        name = icon["name"]
        x, y = index % 9 * 120, index // 9 * 98
        tiles.append(f'<g transform="translate({x+36} {y+10}) scale(2)">{icons[name]}</g>'
                     f'<text x="{x+60}" y="{y+80}" text-anchor="middle" fill="#bbb" '
                     f'font-family="monospace" font-size="11">{name}</text>')
    files[ROOT / "assets/icons-rounded-sheet.svg"] = (
        '<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="784" '
        'viewBox="0 0 1080 784" color="#fff"><rect width="1080" height="784" fill="#252525"/>'
        + ''.join(tiles) + '</svg>\n')
    files[ROOT / "assets/folder-rounded-preview.svg"] = (
        '<svg xmlns="http://www.w3.org/2000/svg" width="320" height="180" viewBox="0 0 320 180">'
        '<rect width="160" height="180" fill="#fff"/><rect x="160" width="160" height="180" fill="#000"/>'
        f'<g transform="translate(20 25) scale(5)" color="#000">{icons["folder"]}</g>'
        f'<g transform="translate(180 25) scale(5)" color="#fff">{icons["folder"]}</g></svg>\n')
    for file, content in files.items():
        if check:
            if not file.exists() or file.read_text() != content:
                raise SystemExit(f"Stale generated file: {file.relative_to(ROOT)}")
        else:
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_text(content)
    print(f"{'Verified' if check else 'Built'} {len(icons)} icons and {len(variants)} weather variants")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--fetch", action="store_true", help="Vendor official sources explicitly")
    args = parser.parse_args()
    if args.fetch:
        fetch_sources()
    build(args.check)
