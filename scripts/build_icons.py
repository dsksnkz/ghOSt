#!/usr/bin/env python3
"""Build ghOSt's standalone monochrome SVG assets from owned vector geometry."""
from pathlib import Path
from html import escape
import argparse
import json
import math
from fontTools.pens.recordingPen import RecordingPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.svgLib.path import parse_path

ROOT = Path(__file__).resolve().parents[1]
DESTINATIONS = (ROOT / "config/quickshell/ghost-bar/icons", ROOT / "site/assets/icons")


def rounded_path(data, radius=1.6):
    """Fillet straight joins, including inside corners of closed outlines.

    Curves retain their supplied geometry. Short edges limit the fillet so
    small symbols never collapse. SVGPathPen serializes curves and expanded arcs.
    """
    recording = RecordingPen()
    parse_path(data, recording)
    pen = SVGPathPen(None)
    contour = []
    for command, points in recording.value:
        if command == "moveTo":
            contour = [(command, points)]
        elif command in ("closePath", "endPath"):
            draw_rounded_contour(pen, contour, command == "closePath", radius)
        else:
            contour.append((command, points))
    return pen.getCommands()


def draw_rounded_contour(pen, commands, closed, radius):
    start = commands[0][1][0]
    segments = commands[1:]
    if not segments:
        pen.moveTo(start)
        pen.endPath()
        return
    if closed and segments[-1][1][-1] != start:
        segments.append(("lineTo", (start,)))
    vertices = [start] + [points[-1] for _, points in segments]
    count = len(vertices) - int(closed)
    corners = {}
    for index in range(count):
        if not closed and index in (0, count - 1):
            continue
        incoming = segments[(index - 1) % len(segments)][0]
        outgoing = segments[index % len(segments)][0]
        if incoming != "lineTo" or outgoing != "lineTo":
            continue
        vertex = vertices[index]
        before, after = vertices[(index - 1) % count], vertices[(index + 1) % count]
        a = (before[0] - vertex[0], before[1] - vertex[1])
        b = (after[0] - vertex[0], after[1] - vertex[1])
        lengths = math.hypot(*a), math.hypot(*b)
        if min(lengths) < .001 or abs(a[0] * b[1] - a[1] * b[0]) < .001:
            continue
        trim = min(radius, lengths[0] * .3, lengths[1] * .3)
        corners[index] = tuple((vertex[0] + delta[0] / length * trim,
                                vertex[1] + delta[1] / length * trim)
                               for delta, length in zip((a, b), lengths))
    pen.moveTo(corners.get(0, (start, start))[1])
    for index, (command, points) in enumerate(segments):
        endpoint = (index + 1) % count if closed else index + 1
        if endpoint in corners:
            before, after = corners[endpoint]
            pen.lineTo(before)
            pen.qCurveTo(vertices[endpoint], after)
        else:
            getattr(pen, command)(*points)
    pen.closePath() if closed else pen.endPath()


def path(d):
    return f'<path d="{rounded_path(d)}"/>'


def circle(x, y, r):
    return f'<circle cx="{x}" cy="{y}" r="{r}"/>'


def rect(x, y, w, h, radius=2.6):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}"/>'


def gear():
    points = []
    for i in range(32):
        radius = 10 if i % 4 in (0, 3) else 7.5
        angle = i * math.pi / 16
        points.append(f'{12 + math.cos(angle) * radius:.4f} {12 + math.sin(angle) * radius:.4f}')
    outline = 'M' + 'L'.join(points) + 'Z M12 8a4 4 0 1 0 0 8a4 4 0 1 0 0-8Z'
    return f'<path d="{rounded_path(outline, .65)}" fill="currentColor" stroke="none" fill-rule="evenodd"/>'


# No external icon set, font symbols or raster embeds. Brand outline is the
# user's requested Turret Road G; its separately bundled OFL remains applicable.
def rounded_folder():
    """Round both negative-space cavities, not just the outer silhouette."""
    outer = "M6 4.5h3.3q1.2 0 2.05.85L13 7q.5.5 1.2.5H18q3 0 3 3V18q0 3-3 3H6q-3 0-3-3V7.5q0-3 3-3Z"
    tab_opening = "M6 6h3.3q.6 0 1 .4L12 8.1q1 1 2.2 1H18q1.5 0 1.5 1.5v.15q0 .75-.75.75H5.25q-.75 0-.75-.75V7.5Q4.5 6 6 6Z"
    body_opening = "M6 13h12q1.5 0 1.5 1.5V18q0 1.5-1.5 1.5H6q-1.5 0-1.5-1.5v-3.5Q4.5 13 6 13Z"
    return f'<path d="{outer} {tab_opening} {body_opening}" fill="currentColor" stroke="none" fill-rule="evenodd"/>'


ICONS = {
    "settings": ("System", gear()),
    "wifi": ("Connections", path("M3 8a14 14 0 0 1 18 0M6 12a9 9 0 0 1 12 0M9 16a4.5 4.5 0 0 1 6 0") + circle(12, 19, .7)),
    "network": ("Connections", rect(9, 3, 6, 5) + rect(3, 16, 6, 5) + rect(15, 16, 6, 5) + path("M12 8v4M6 16v-4h12v4")),
    "ethernet": ("Connections", path("M6 3h12v7l-3 3H9l-3-3ZM9 3v4m3-4v4m3-4v4M12 13v8m-5 0h10")),
    "bluetooth": ("Connections", path("M12 2v20l6-6L6 6m6-4 6 6L6 18")),
    "display": ("System", rect(3, 4, 18, 12) + path("M12 16v4m-5 0h10")),
    "brightness": ("System", circle(12, 12, 4) + path("M12 2v2m0 16v2M2 12h2m16 0h2M5 5l1.5 1.5m11 11L19 19M5 19l1.5-1.5m11-11L19 5")),
    "volume": ("System", path("M3 9h4l5-4v14l-5-4H3ZM16 8a6 6 0 0 1 0 8m3-11a10 10 0 0 1 0 14")),
    "mute": ("System", path("M3 9h4l5-4v14l-5-4H3ZM16 9l5 6m0-6-5 6")),
    "microphone": ("System", rect(9, 3, 6, 12, 3) + path("M5 11v1a7 7 0 0 0 14 0v-1M12 19v3m-4 0h8")),
    "notifications": ("System", path("M5 17h14l-2-3V9a5 5 0 0 0-10 0v5ZM10 20a2 2 0 0 0 4 0M12 2v2")),
    "appearance": ("Personal", circle(12, 12, 9) + '<path d="M12 3a9 9 0 0 1 0 18Z" fill="currentColor" stroke="none"/>'),
    "wallpaper": ("Personal", rect(3, 3, 18, 18) + circle(8, 8, 1.5) + path("M3 17l6-6 4 4 3-3 5 5")),
    "keyboard": ("Input", rect(2, 5, 20, 14) + path("M5 9h1m3 0h1m3 0h1m3 0h2M5 12h1m3 0h1m3 0h1m3 0h2M7 16h10")),
    "mouse": ("Input", rect(6, 2, 12, 20, 6) + path("M12 2v8M6 10h12")),
    "touchpad": ("Input", rect(3, 4, 18, 16) + path("M3 15h18m-9 0v5")),
    "accessibility": ("Input", circle(12, 4, 2) + path("M3 9l9 2 9-2M12 11v4m0 0-5 7m5-7 5 7")),
    "language": ("Input", path("M3 5h11M8 2v3m-3 0c0 5 4 8 8 10M12 5c0 5-4 9-9 11M13 21l4-11 4 11m-6.5-4h5")),
    "calendar": ("System", rect(3, 5, 18, 16) + path("M3 10h18M7 3v4m10-4v4M7 14h2m4 0h2m-8 4h2")),
    "clock": ("System", circle(12, 12, 9) + path("M12 6v6l4 2")),
    "battery": ("System", rect(2, 6, 18, 12) + path("M22 10v4M5 9v6m3-6v6m3-6v6")),
    "power": ("Session", path("M12 2v10M6 5a9 9 0 1 0 12 0")),
    "storage": ("System", path("M5 4h14l3 10v6H2v-6ZM2 14h20") + circle(17, 17, .7)),
    "app": ("Personal", "".join(rect(x, y, 6, 6) for y in (4, 14) for x in (4, 14))),
    "accounts": ("Personal", circle(12, 7, 4) + path("M4 21v-2a8 8 0 0 1 16 0v2Z")),
    "privacy": ("Personal", path("M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12Z") + circle(12, 12, 3)),
    "security": ("Personal", path("M12 2 3 6v6c0 5 9 10 9 10s9-5 9-10V6ZM8 12l3 3 5-6")),
    "lock": ("Session", rect(5, 10, 14, 11) + path("M8 10V6a4 4 0 0 1 8 0v4M12 14v3")),
    "updates": ("System", path("M20 9a8 8 0 0 0-14-4L3 8m0-5v5h5M4 15a8 8 0 0 0 14 4l3-3m0 5v-5h-5")),
    "info": ("Actions", circle(12, 12, 9) + path("M12 11v6m-2 0h4") + circle(12, 7, .5)),
    "search": ("Actions", circle(10, 10, 6) + path("m15 15 6 6")),
    "edit": ("Actions", path("M4 20l1-5L16 4a2.12 2.12 0 0 1 3 3L8 18ZM14 6l4 4")),
    "close": ("Actions", path("m6 6 12 12M18 6 6 18")),
    "check": ("Actions", path("m4 12 5 5L20 6")),
    "plus": ("Actions", path("M12 4v16M4 12h16")),
    "minus": ("Actions", path("M4 12h16")),
    "back": ("Actions", path("m14 5-7 7 7 7")),
    "forward": ("Actions", path("m10 5 7 7-7 7")),
    "up": ("Actions", path("m5 14 7-7 7 7")),
    "workspace-indicator": ("Actions", f'<path d="{rounded_path("M2 22 12 2 22 22Z", 1.2)}" fill="currentColor" stroke="none"/>'),
    "down": ("Actions", path("m5 10 7 7 7-7")),
    "menu": ("Actions", path("M4 6h16M4 12h16M4 18h16")),
    "pin": ("Actions", path("M8 3h8M9 3v6l-3 5h12l-3-5V3M12 14v8")),
    "folder": ("Personal", rounded_folder()),
    "folder-rounded": ("Personal", rounded_folder()),
    "terminal": ("Personal", rect(2, 4, 20, 16) + path("m6 9 3 3-3 3m7 1h5")),
    "browser": ("Personal", circle(12, 12, 9) + '<ellipse cx="12" cy="12" rx="4" ry="9"/>' + path("M3 12h18")),
    "cpu": ("Hardware", rect(6, 6, 12, 12) + rect(9, 9, 6, 6) + path("M8 2v4m4-4v4m4-4v4M8 18v4m4-4v4m4-4v4M2 8h4m-4 4h4m-4 4h4m12-8h4m-4 4h4m-4 4h4")),
    "gpu": ("Hardware", path("M3 5h14l4 4v9H3ZM3 21h13M6 18v3m4-3v3m4-3v3") + circle(12, 11, 4) + path("M12 8v6m-3-3h6")),
    "memory": ("Hardware", rect(2, 6, 20, 11) + rect(5, 9, 5, 5) + rect(14, 9, 5, 5) + path("M5 17v4m4-4v4m6-4v4m4-4v4")),
    "play": ("Media", path("m8 4 12 8-12 8Z")),
    "pause": ("Media", path("M8 5v14m8-14v14")),
    "previous": ("Media", path("M5 4v16M19 4 8 12l11 8Z")),
    "next": ("Media", path("M19 4v16M5 4l11 8-11 8Z")),
    "logout": ("Session", path("M10 3H3v18h7M9 12h12m-5-5 5 5-5 5")),
    "restart": ("Session", path("M20 12a8 8 0 1 1-2.343-5.657M18 3v4h-4")),
    "sleep": ("Session", path("M18 15A9 9 0 0 1 9 3a9 9 0 1 0 12 12 9 9 0 0 1-3 0Z")),
    "cloud": ("Weather", path("M7 18h11c5 0 5-8 0-8C17 3 7 3 6 10c-5 0-5 8 1 8Z")),
    "rain": ("Weather", path("M6 14C2 14 2 8 6 8c1-6 10-6 11 0 6-1 6 6 2 6M7 17l-1 4m6-4-1 4m6-4-1 4")),
    "storm": ("Weather", path("M6 15C1 15 1 8 6 8c1-6 10-6 11 0 6-1 6 7 2 7M13 10l-5 7h7l-4 5")),
    "lightning": ("Weather", path("M14 3 5 14h8l-3 7 9-11h-8Z")),
    "snow": ("Weather", path("M12 2v20M3.3 7l17.4 10M3.3 17 20.7 7M9 4l3 3 3-3M9 20l3-3 3 3M3 10l4-1-1-4M21 14l-4 1 1 4M3 14l4 1-1 4M21 10l-4-1 1-4")),
    "dot": ("Actions", circle(12, 12, 2)),
}


def brand():
    from fontTools.ttLib import TTFont
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.boundsPen import BoundsPen
    font = TTFont(ROOT / "config/quickshell/ghost-bar/fonts/TurretRoad-Bold.ttf")
    glyphs = font.getGlyphSet()
    glyph = glyphs[font.getBestCmap()[ord("G")]]
    bounds = BoundsPen(glyphs)
    glyph.draw(bounds)
    x0, y0, x1, y1 = bounds.bounds
    scale = 18 / max(x1 - x0, y1 - y0)
    pen = SVGPathPen(glyphs)
    glyph.draw(pen)
    tx = 12 - (x0 + x1) * scale / 2
    ty = 12 + (y0 + y1) * scale / 2
    outline = rounded_path(pen.getCommands(), .5 / scale)
    return f'<path transform="matrix({scale} 0 0 {-scale} {tx} {ty})" d="{outline}" fill="currentColor" stroke="none"/>'


def definitions():
    return {**ICONS, "ghost": ("Brand", brand())}


def svg(name, geometry, color):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" '
            f'fill="none" color="{color}" stroke="currentColor" stroke-width="2" '
            f'stroke-linecap="round" stroke-linejoin="round"><title>{escape(name)}</title>{geometry}</svg>\n')


def build(check=False):
    icons = definitions()
    files = {}
    # A reproducible full-set inspection sheet, not a second icon source.
    tiles = []
    for index, (name, (_, geometry)) in enumerate(icons.items()):
        x, y = (index % 9) * 120, (index // 9) * 98
        tiles.append(f'<g transform="translate({x + 36} {y + 10}) scale(2)" '
                     f'fill="none" stroke="currentColor" stroke-width="2" '
                     f'stroke-linecap="round" stroke-linejoin="round">{geometry}</g>'
                     f'<text x="{x + 60}" y="{y + 80}" text-anchor="middle" '
                     f'fill="#bbb" font-family="monospace" font-size="11">{name}</text>')
    files[ROOT / "assets/icons-rounded-sheet.svg"] = (
        '<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="784" '
        'viewBox="0 0 1080 784" color="#fff"><rect width="1080" height="784" fill="#252525"/>'
        + ''.join(tiles) + '</svg>\n')
    files[ROOT / "assets/folder-rounded-preview.svg"] = (
        '<svg xmlns="http://www.w3.org/2000/svg" width="320" height="180" viewBox="0 0 320 180">\n'
        '  <rect width="160" height="180" fill="#fff"/>\n'
        '  <rect x="160" width="160" height="180" fill="#000"/>\n'
        f'  <g transform="translate(20 25) scale(5)" color="#000">{rounded_folder()}</g>\n'
        f'  <g transform="translate(180 25) scale(5)" color="#fff">{rounded_folder()}</g>\n'
        '</svg>\n'
    )
    files[ROOT / "config/quickshell/ghost-bar/IconCatalogue.js"] = "// Generated by scripts/build_icons.py\nvar names = " + json.dumps(list(icons)) + ";\n"
    for directory in DESTINATIONS:
        for name, (_, geometry) in icons.items():
            for tone, color in (("black", "#000000"), ("white", "#ffffff")):
                files[directory / tone / f"{name}.svg"] = svg(name, geometry, color)
        files[directory / "manifest.json"] = json.dumps(
            [{"name": name, "category": category} for name, (category, _) in icons.items()], indent=2) + "\n"
    for file, content in files.items():
        if check:
            if not file.exists() or file.read_text() != content:
                raise SystemExit(f"Stale generated file: {file.relative_to(ROOT)}")
        else:
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_text(content)
    print(f"{'Verified' if check else 'Built'} {len(icons)} icons in two tones, shell and web copies")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    build(parser.parse_args().check)
