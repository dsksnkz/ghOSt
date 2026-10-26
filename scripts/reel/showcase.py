#!/usr/bin/env python3
"""ghOSt desktop showcase: a 20-second, 4K/60 'screen recording' in the r/unixporn style.

Built from real ghOSt captures (rail, launcher, toast, media popup, Intro app; see
capture.py) placed in a tiled Hyprland-style desktop with ghOSt's own behaviour:
the rail slides in, launcher and media slide down from under the rail, toasts
appear top-centre. Terminal, btop, editor and browser contents are drawn here.
Output: .local/reel/ghOSt-showcase.mp4 (and a 1080p share copy).
"""
from functools import lru_cache
import math
from multiprocessing import Pool
from pathlib import Path
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / '.local/reel'
MUSIC = Path.home() / 'Downloads/mixkit-cbpd-400-20s-drop2.mp3'
OUTPUT = ASSETS / 'ghOSt-showcase.mp4'
S = 2                                  # render scale: 1920 × 1080 design plane at 4K
W, H, FPS, DURATION = 1920 * S, 1080 * S, 60, 20.0

KICKS = [1.96, 2.58, 3.2, 3.825, 4.86, 5.275, 5.9, 6.52, 7.145, 8.18, 8.595, 9.215, 9.84,
         10.46, 11.495, 11.91, 12.535, 13.155, 13.78, 14.815, 15.23, 15.85, 16.475, 17.095,
         18.135, 18.55, 19.205]
CLAPS = [2.775, 4.43, 6.09, 7.75, 9.41, 11.07, 12.725, 14.385, 16.045, 17.705, 19.37]
BARS = [1.96 + 1.6588 * index for index in range(12)]

MONO = str(ROOT / 'config/quickshell/ghost-bar/fonts/JetBrainsMono-Regular.ttf')
MONO_BOLD = str(ROOT / 'config/quickshell/ghost-bar/fonts/JetBrainsMono-Bold.ttf')
SANS = '/usr/share/fonts/Adwaita/AdwaitaSans-Regular.ttf'
INK = (236, 236, 234)
DIM = (128, 128, 126)
FAINT = (70, 70, 70)

# Layout: rail reserves the top, generous gaps between tiles (design pixels).
TOP, GAP_OUT, GAP_IN = 64, 18, 12
AREA = (GAP_OUT, TOP, 1920 - GAP_OUT, 1080 - GAP_OUT)
RADIUS = 12


# ── timing helpers ──────────────────────────────────────────────────────────
def clamp(x):
    return max(0.0, min(1.0, x))


def ease(x):
    return 1 - (1 - clamp(x)) ** 3


def ease_io(x):
    x = clamp(x)
    return x * x * (3 - 2 * x)


def spring(x):
    """Settles to 1 with one soft overshoot (Hyprland-style popin)."""
    x = clamp(x)
    return 1 - math.exp(-5.5 * x) * math.cos(7.5 * x) if x < 1 else 1.0


def since(t, start, length):
    return ease((t - start) / length)


# ── assets ──────────────────────────────────────────────────────────────────
@lru_cache(maxsize=64)
def load(name):
    with Image.open(ASSETS / name) as image:
        return image.convert('RGBA')


@lru_cache(maxsize=16)
def fitted(name, width, height):
    return load(name).resize((width, height), Image.Resampling.LANCZOS)


@lru_cache(maxsize=1)
def wallpaper():
    with Image.open(Path.home() / 'Documents/ghostpaper.png') as source:
        return source.convert('RGBA').resize((round(W * 1.08), round(H * 1.08)), Image.Resampling.LANCZOS)


@lru_cache(maxsize=1)
def wallpaper_blur():
    return wallpaper().filter(ImageFilter.GaussianBlur(26 * S))


@lru_cache(maxsize=64)
def font(size, bold=False, sans=False, weight=None):
    if sans:
        face = ImageFont.truetype(SANS, size)
        face.set_variation_by_name(weight or 'Regular')
        return face
    return ImageFont.truetype(MONO_BOLD if bold else MONO, size)


@lru_cache(maxsize=1)
def vignette():
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    d = np.sqrt(((x - W / 2) / (W / 2)) ** 2 + ((y - H / 2) / (H / 2)) ** 2)
    return (1 - .28 * np.clip(d - .55, 0, 1) ** 1.6)[..., None].astype(np.float32)


@lru_cache(maxsize=1)
def grain(seed):
    return np.random.default_rng(seed).normal(0, 3.2, (H, W, 1)).astype(np.float32)


# ── window contents (drawn at render scale) ─────────────────────────────────
@lru_cache(maxsize=1)
def ghost_ascii():
    """The ghost mark as half-block characters: an original logo, no brand marks."""
    with Image.open(ASSETS / 'ghost-mark.png') as mark:
        alpha = mark.getchannel('A').resize((24, 26), Image.Resampling.LANCZOS)
        body = mark.convert('L').resize((24, 26), Image.Resampling.LANCZOS)
    a, b = np.asarray(alpha) > 110, np.asarray(body) > 110
    on = a & b
    rows = []
    for y in range(0, 26, 2):
        row = ''
        for x in range(24):
            top, bottom = on[y, x], on[y + 1, x] if y + 1 < 26 else False
            row += '█' if top and bottom else '▀' if top else '▄' if bottom else ' '
        rows.append(row.rstrip())
    return rows


FETCH = [('', 'user@ghost'), ('', '──────────'), ('OS', 'Arch Linux x86_64'), ('Kernel', '7.2.7-arch1-1'),
         ('WM', 'Hyprland 0.56'), ('Shell', 'ghOSt (Quickshell)'), ('Theme', 'ghOSt monochrome'),
         ('Terminal', 'kitty'), ('Font', 'JetBrains Mono'), ('Display', '1920x1080 @ 200 Hz')]


def terminal_fetch(w, h, t, start):
    image = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    f, fb = font(15 * S), font(15 * S, bold=True)
    line = 22 * S
    x0, y0 = 22 * S, 22 * S
    draw.text((x0, y0), '~', font=fb, fill=INK)
    command = 'fastfetch'
    typed = command[:int(len(command) * clamp((t - start - .1) / .35))]
    draw.text((x0 + 22 * S, y0), typed + ('█' if t - start < .55 else ''), font=f, fill=INK)
    if t - start < .55:
        return image
    shown = (t - start - .55) / .5
    art = ghost_ascii()
    for i, row in enumerate(art):
        if i / len(art) <= shown:
            draw.text((x0, y0 + (2 + i) * line * .9), row, font=f, fill=INK)
    ix = x0 + 30 * 9 * S
    for i, (key, value) in enumerate(FETCH):
        if i / len(FETCH) > shown:
            break
        y = y0 + (2 + i) * line
        if key:
            draw.text((ix, y), key, font=fb, fill=INK)
            draw.text((ix + 10 * 9 * S, y), value, font=f, fill=DIM)
        else:
            draw.text((ix, y), value, font=fb if i == 0 else f, fill=INK if i == 0 else DIM)
    if shown > 1:
        y = y0 + (2 + len(FETCH) + .5) * line
        for i, shade in enumerate([30, 60, 95, 130, 165, 200, 236]):
            draw.rectangle([ix + i * 26 * S, y, ix + i * 26 * S + 22 * S, y + 14 * S], fill=(shade,) * 3 + (255,))
        draw.text((x0, y0 + 15 * line), '~', font=fb, fill=INK)
        if int(t * 2) % 2:
            draw.text((x0 + 22 * S, y0 + 15 * line), '█', font=f, fill=INK)
    return image


PROCS = [('quickshell', 2.1, 172), ('Hyprland', 1.4, 62), ('kitty', .8, 96), ('pipewire', .6, 22),
         ('nvim', .4, 84), ('btop', .3, 9), ('wireplumber', .2, 18), ('cava', .2, 6)]


def btop(w, h, t):
    image = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    f, fb, small = font(14 * S), font(14 * S, bold=True), font(12 * S)
    pad = 14 * S

    def box(x0, y0, x1, y1, title):
        draw.rounded_rectangle([x0, y0, x1, y1], 6 * S, outline=FAINT + (255,), width=S)
        draw.rectangle([x0 + 14 * S, y0 - 9 * S, x0 + 14 * S + len(title) * 9 * S + 10 * S, y0 + 9 * S],
                       fill=(18, 18, 19, 255))
        draw.text((x0 + 19 * S, y0 - 9 * S), title, font=fb, fill=INK)

    # CPU: scrolling braille-like bar graph.
    cx0, cy0, cx1, cy1 = pad, pad + 6 * S, w - pad, int(h * .42)
    box(cx0, cy0, cx1, cy1, 'cpu')
    cols = (cx1 - cx0 - 30 * S) // (5 * S)
    for i in range(cols):
        phase = t * 3 + i * .19
        v = .28 + .22 * math.sin(phase) + .18 * math.sin(phase * 2.7 + 1) + .1 * math.sin(i * 1.3 + t * 9)
        v = clamp(v)
        x = cx0 + 15 * S + i * 5 * S
        top = cy1 - 12 * S - v * (cy1 - cy0 - 40 * S)
        shade = round(90 + 146 * v)
        draw.rectangle([x, top, x + 3 * S, cy1 - 12 * S], fill=(shade,) * 3 + (255,))
    draw.text((cx1 - 120 * S, cy0 + 14 * S), f'{round(24 + 9 * math.sin(t * 2))}%', font=fb, fill=INK)
    # Memory bars.
    my0, my1 = cy1 + 22 * S, int(h * .62)
    box(cx0, my0, int(w * .5) - 6 * S, my1, 'mem')
    for i, (name, value) in enumerate([('used', .46), ('cache', .31), ('free', .23)]):
        y = my0 + 24 * S + i * 30 * S
        draw.text((cx0 + 18 * S, y), name, font=small, fill=DIM)
        bx = cx0 + 84 * S
        bw = int(w * .5) - 6 * S - bx - 20 * S
        draw.rectangle([bx, y + 4 * S, bx + bw, y + 14 * S], fill=(34, 34, 35, 255))
        draw.rectangle([bx, y + 4 * S, bx + bw * (value + .02 * math.sin(t * 3 + i)), y + 14 * S],
                       fill=(200 - i * 50,) * 3 + (255,))
    # Network sparkline.
    box(int(w * .5) + 6 * S, my0, cx1, my1, 'net')
    nx0, nx1 = int(w * .5) + 24 * S, cx1 - 18 * S
    points = [(nx0 + (nx1 - nx0) * i / 59, my1 - 20 * S - (my1 - my0 - 50 * S) *
               clamp(.35 + .3 * math.sin(i * .4 + t * 4) * math.sin(i * .13 + t))) for i in range(60)]
    draw.line(points, fill=INK + (255,), width=2 * S)
    # Processes.
    py0 = my1 + 22 * S
    box(cx0, py0, cx1, h - pad, 'proc')
    draw.text((cx0 + 18 * S, py0 + 18 * S), 'program', font=fb, fill=DIM)
    draw.text((cx1 - 230 * S, py0 + 18 * S), 'cpu%   mem', font=fb, fill=DIM)
    for i, (name, cpu, mem) in enumerate(PROCS):
        y = py0 + 46 * S + i * 24 * S
        if y > h - pad - 30 * S:
            break
        shade = INK if i == 0 else (190, 190, 188)
        draw.text((cx0 + 18 * S, y), name, font=f, fill=shade)
        draw.text((cx1 - 230 * S, y), f'{cpu + .3 * math.sin(t * 5 + i):4.1f}   {mem:3d}M', font=f, fill=shade)
    return image


@lru_cache(maxsize=1)
def code_lines():
    path = ROOT / 'config/quickshell/ghost-bar/RevealGate.qml'
    return path.read_text().splitlines()


KEYWORDS = ('import', 'property', 'function', 'const', 'if', 'else', 'readonly', 'onTriggered', 'id:',
            'running', 'return', 'bool', 'real', 'int')


@lru_cache(maxsize=1)
def editor_static(w, h):
    image = Image.new('RGBA', (w, h), (13, 13, 14, 255))
    draw = ImageDraw.Draw(image)
    f, fb = font(15 * S), font(15 * S, bold=True)
    line = 23 * S
    draw.rectangle([0, 0, w, 34 * S], fill=(20, 20, 21, 255))
    draw.text((16 * S, 8 * S), ' RevealGate.qml ', font=fb, fill=(13, 13, 14), stroke_width=0)
    draw.rectangle([10 * S, 6 * S, 10 * S + 150 * S, 28 * S], fill=INK + (255,))
    draw.text((18 * S, 8 * S), 'RevealGate.qml', font=fb, fill=(13, 13, 14))
    draw.text((180 * S, 8 * S), 'Panel.qml   PanelMotion.js', font=f, fill=DIM)
    for i, text in enumerate(code_lines()[:int((h - 90 * S) / line)]):
        y = 48 * S + i * line
        draw.text((14 * S, y), f'{i + 1:3d}', font=f, fill=FAINT)
        x = 70 * S
        stripped = text.lstrip()
        if stripped.startswith('//'):
            draw.text((x, y), text, font=f, fill=(110, 110, 108))
            continue
        for token in text.split(' '):
            color = INK if token.strip() in KEYWORDS else (205, 205, 203) if token.strip().endswith(':') else (160, 160, 158)
            if token.startswith('"') or token.startswith("'"):
                color = (200, 200, 198)
            face = fb if token.strip() in KEYWORDS else f
            draw.text((x, y), token, font=face, fill=color)
            x += draw.textlength(token + ' ', font=face)
    # Status line.
    draw.rectangle([0, h - 34 * S, w, h], fill=(20, 20, 21, 255))
    draw.rectangle([0, h - 34 * S, 96 * S, h], fill=INK + (255,))
    draw.text((16 * S, h - 27 * S), 'NORMAL', font=fb, fill=(13, 13, 14))
    draw.text((112 * S, h - 27 * S), 'RevealGate.qml   qml   utf-8', font=f, fill=DIM)
    draw.text((w - 120 * S, h - 27 * S), '24:9   top', font=f, fill=DIM)
    return image


def editor(w, h, t):
    image = editor_static(w, h).copy()
    if int(t * 2.2) % 2 == 0:
        ImageDraw.Draw(image).rectangle([70 * S + 9 * 8 * S, 48 * S + 23 * 23 * S, 70 * S + 9 * 9 * S,
                                         48 * S + 24 * 23 * S - 3 * S], fill=INK + (255,))
    return image


@lru_cache(maxsize=2)
def browser(w, h):
    image = Image.new('RGBA', (w, h), (15, 15, 16, 255))
    draw = ImageDraw.Draw(image)
    f, small = font(14 * S, sans=True), font(13 * S, sans=True)
    draw.rectangle([0, 0, w, 44 * S], fill=(22, 22, 23, 255))
    draw.rounded_rectangle([12 * S, 8 * S, 230 * S, 44 * S], 8 * S, fill=(15, 15, 16, 255))
    draw.text((28 * S, 17 * S), 'New Tab', font=f, fill=INK)
    draw.rounded_rectangle([12 * S, 52 * S, w - 12 * S, 86 * S], 17 * S, fill=(26, 26, 27, 255))
    draw.text((32 * S, 60 * S), 'ghost://start', font=f, fill=DIM)
    cx = w // 2
    big = font(110 * S, sans=True, weight='Light')
    draw.text((cx, int(h * .34)), '09:21', font=big, fill=INK, anchor='mm')
    draw.text((cx, int(h * .34) + 82 * S), 'Tuesday 29 September', font=font(20 * S, sans=True), fill=DIM,
              anchor='mm')
    sy = int(h * .34) + 140 * S
    draw.rounded_rectangle([cx - 300 * S, sy, cx + 300 * S, sy + 52 * S], 26 * S, fill=(26, 26, 27, 255),
                           outline=(48, 48, 49, 255), width=S)
    draw.text((cx - 270 * S, sy + 15 * S), 'Search or enter address', font=f, fill=DIM)
    for i, name in enumerate(['mail', 'code', 'music', 'notes', 'wiki']):
        x = cx - 290 * S + i * 120 * S
        y = sy + 100 * S
        draw.rounded_rectangle([x, y, x + 100 * S, y + 80 * S], 12 * S, fill=(24, 24, 25, 255))
        draw.text((x + 50 * S, y + 58 * S), name, font=small, fill=DIM, anchor='mm')
        draw.ellipse([x + 38 * S, y + 16 * S, x + 62 * S, y + 40 * S], outline=(120, 120, 118, 255), width=2 * S)
    return image


@lru_cache(maxsize=1)
def shell_files():
    return sorted(p.name for p in (ROOT / 'config/quickshell/ghost-bar').iterdir()
                  if p.is_file() and not p.name.startswith('.'))


def terminal_ls(w, h, t, start):
    image = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    f, fb = font(14 * S), font(14 * S, bold=True)
    line = 21 * S
    x0, y0 = 20 * S, 20 * S
    draw.text((x0, y0), '~', font=fb, fill=INK)
    command = 'ls ~/.config/quickshell/ghost-bar'
    typed = command[:int(len(command) * clamp((t - start - .08) / .3))]
    draw.text((x0 + 22 * S, y0), typed, font=f, fill=INK)
    if t - start > .42:
        files = shell_files()
        cols = max(1, (w - 40 * S) // (190 * S))
        shown = int(len(files) * clamp((t - start - .42) / .35))
        for i, name in enumerate(files[:shown]):
            col, row = i % cols, i // cols
            y = y0 + (1.6 + row) * line
            if y > h - 30 * S:
                break
            folder_like = name.endswith('.qml')
            draw.text((x0 + col * 190 * S, y), name, font=fb if folder_like else f,
                      fill=INK if folder_like else DIM)
    return image


@lru_cache(maxsize=2)
def intro_content(w, h):
    image = Image.new('RGBA', (w, h), (20, 20, 21, 255))
    panel = load('intro.png')
    scale = min(w / panel.width, h / panel.height)
    fitted_panel = panel.resize((round(panel.width * scale), round(panel.height * scale)), Image.Resampling.LANCZOS)
    image.alpha_composite(fitted_panel, ((w - fitted_panel.width) // 2, (h - fitted_panel.height) // 2))
    return image


# ── window compositing ──────────────────────────────────────────────────────
@lru_cache(maxsize=2)
def rounded_mask(w, h, r):
    mask = Image.new('L', (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, h - 1], r, fill=255)
    return mask


@lru_cache(maxsize=2)
def ring_mask(w, h, r):
    mask = Image.new('L', (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, h - 1], r, outline=255, width=S)
    return np.asarray(mask)


@lru_cache(maxsize=2)
def shadow(w, h):
    pad = 60 * S
    image = Image.new('RGBA', (w + 2 * pad, h + 2 * pad), (0, 0, 0, 0))
    ImageDraw.Draw(image).rounded_rectangle([pad, pad + 14 * S, pad + w, pad + h + 14 * S], RADIUS * S,
                                            fill=(0, 0, 0, 150))
    return image.filter(ImageFilter.GaussianBlur(26 * S)), pad


def sheen(w, h, t, strength):
    """Faint white hairline with a slow travelling highlight (monochrome)."""
    ring = ring_mask(w, h, RADIUS * S).astype(np.float32) / 255
    angle = t * .6
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    proj = ((x / w - .5) * math.cos(angle) + (y / h - .5) * math.sin(angle))
    light = .25 + .75 * np.clip(proj * 2.2, 0, 1) ** 2
    alpha = (ring * light * 255 * strength).astype(np.uint8)
    out = np.zeros((h, w, 4), np.uint8)
    out[..., :3] = 255
    out[..., 3] = alpha
    return Image.fromarray(out, 'RGBA')


class Win:
    def __init__(self, rect, draw, frosted=False, active=True, solid=(17, 17, 18)):
        self.rect, self.draw, self.frosted, self.active, self.solid = rect, draw, frosted, active, solid


def place_window(frame, win, t, scale=1.0, opacity=1.0, dx=0.0, wall_offset=(0, 0)):
    x0, y0, x1, y1 = win.rect
    w, h = round((x1 - x0) * S), round((y1 - y0) * S)
    if w < 8 or h < 8 or opacity <= .01:
        return
    body = Image.new('RGBA', (w, h), win.solid + (255,))
    if win.frosted:
        blur = wallpaper_blur()
        bx, by = round(x0 * S - wall_offset[0] + dx * S), round(y0 * S - wall_offset[1])
        crop = blur.crop((bx, by, bx + w, by + h))
        body = crop.copy()
        body.alpha_composite(Image.new('RGBA', (w, h), (10, 10, 11, 150)))
    body.alpha_composite(win.draw(w, h, t))
    alpha = rounded_mask(w, h, RADIUS * S)
    if not win.active:
        alpha = alpha.point(lambda v: round(v * .87))
    body.putalpha(alpha)
    body.alpha_composite(sheen(w, h, t, .55 if win.active else .25))
    sh, pad = shadow(w, h)
    if abs(scale - 1) > .002:
        sw, shh = max(2, round(w * scale)), max(2, round(h * scale))
        body = body.resize((sw, shh), Image.Resampling.BILINEAR)
        sh = sh.resize((max(2, round(sh.width * scale)), max(2, round(sh.height * scale))), Image.Resampling.BILINEAR)
        pad = round(pad * scale)
    if opacity < .999:
        body.putalpha(body.getchannel('A').point(lambda v: round(v * opacity)))
        sh.putalpha(sh.getchannel('A').point(lambda v: round(v * opacity)))
    cx, cy = (x0 + x1) / 2 * S + dx * S, (y0 + y1) / 2 * S
    frame.alpha_composite(sh, (round(cx - body.width / 2 - pad), round(cy - body.height / 2 - pad)))
    frame.alpha_composite(body, (round(cx - body.width / 2), round(cy - body.height / 2)))


# ── layouts ─────────────────────────────────────────────────────────────────
def full():
    return AREA


def split(left_fraction, side):
    x0, y0, x1, y1 = AREA
    mid = x0 + (x1 - x0) * left_fraction
    return (x0, y0, mid - GAP_IN / 2, y1) if side == 0 else (mid + GAP_IN / 2, y0, x1, y1)


def lerp_rect(a, b, f):
    return tuple(a[i] + (b[i] - a[i]) * f for i in range(4))


T_TERM1 = BARS[1]          # 3.62: first terminal pops open
T_TERM2 = BARS[2]          # 5.28: btop tiles in beside it
T_WS2, T_WS3 = BARS[3], BARS[4]
T_LAUNCH = BARS[5]         # 10.26: launcher slides down
TYPE_TIMES = [10.46, 10.6, 10.74, 10.88, 11.02]
T_ENTER = KICKS[14]        # 11.495: Enter opens ghOSt Intro (a floating window in ghOSt)
T_TILE = KICKS[15]         # 11.91: a terminal tiles in beside the browser (dwindle)
T_TOAST = BARS[7]          # 13.58
T_MEDIA = BARS[8]          # 15.24
T_PUSH = BARS[9]           # 16.90
CLOSE = [KICKS[25], KICKS[26], CLAPS[10]]   # 18.55, 19.205, 19.37


def workspace_shift(t):
    """Horizontal workspace slide (snappy ease-out): returns (index float)."""
    return min(1, ease((t - T_WS2) / .42)) + min(1, ease((t - T_WS3) / .42))


def wheel_frame(t):
    return 13 * (min(1, ease((t - T_WS2) / .42)) + min(1, ease((t - T_WS3) / .42)))


def render_frame(index):
    t = min(DURATION - .5 / FPS, index / FPS)
    frame = Image.new('RGBA', (W, H), (8, 8, 9, 255))
    # Wallpaper: drifts in slowly; slight parallax with workspace slides.
    wall = wallpaper()
    ws = workspace_shift(t)
    ox = (wall.width - W) / 2 + math.sin(t * .18) * 22 * S + ws * 18 * S
    oy = (wall.height - H) / 2 + (1 - ease(t / 2.4)) * 30 * S
    wall_offset = (round(ox), round(oy))
    frame.alpha_composite(wall.crop((wall_offset[0], wall_offset[1], wall_offset[0] + W, wall_offset[1] + H)))
    if t < 1.2:
        frame.alpha_composite(Image.new('RGBA', (W, H), (8, 8, 9, round(255 * (1 - ease_io(t / 1.2))))))

    windows = []   # (win, scale, opacity, dx)
    slide = -1920 * ws  # design px
    # Workspace 1: fetch terminal, then btop tiles in.
    split_f = since(t, T_TERM2, .38)
    if t >= T_TERM1:
        rect1 = lerp_rect(full(), split(.5, 0), split_f)
        pop = spring((t - T_TERM1) / .55)
        windows.append((Win(rect1, lambda w, h, tt: terminal_fetch(w, h, tt, T_TERM1), frosted=True,
                            active=t < T_TERM2), .86 + .14 * pop, clamp((t - T_TERM1) / .2), slide))
    if t >= T_TERM2:
        pop = spring((t - T_TERM2) / .55)
        windows.append((Win(split(.5, 1), btop, frosted=True), .86 + .14 * pop, clamp((t - T_TERM2) / .2), slide))
    # Workspace 2: editor; workspace 3: browser (then ghOSt Intro tiles in).
    windows.append((Win(full(), editor), 1, 1, slide + 1920))
    tile = since(t, T_TILE, .42)
    closing = [clamp((t - c) / .3) for c in CLOSE]
    if closing[2] < 1:
        windows.append((Win(lerp_rect(full(), split(.55, 0), tile), lambda w, h, tt: browser(w, h),
                            active=t < T_ENTER), 1 - .12 * ease(closing[2]), 1 - closing[2], slide + 3840))
    if t >= T_TILE and closing[2] < 1:
        pop = spring((t - T_TILE) / .55)
        windows.append((Win(split(.55, 1), lambda w, h, tt: terminal_ls(w, h, tt, T_TILE), frosted=True,
                            active=False), (.86 + .14 * pop) * (1 - .12 * ease(closing[2])),
                        clamp((t - T_TILE) / .2) * (1 - closing[2]), slide + 3840))
    if t >= T_ENTER and closing[1] < 1:
        pop = spring((t - T_ENTER - .05) / .55)
        fx0, fy0 = (1920 - 860) / 2, 64 + (1016 - 620) / 2
        windows.append((Win((fx0, fy0, fx0 + 860, fy0 + 620), lambda w, h, tt: intro_content(w, h),
                            solid=(20, 20, 21)), (.86 + .14 * pop) * (1 - .12 * ease(closing[1])),
                        clamp((t - T_ENTER) / .2) * (1 - closing[1]), slide + 3840))
    for win, scale, opacity, dx in windows:
        if -1920 < dx < 1920:
            place_window(frame, win, t, scale, opacity, dx, wall_offset)

    # Rail: slides down on the drop. Workspace indicator follows the switches.
    rail = load(f'wheel/{min(39, round(wheel_frame(t))):04d}.png')
    rail = rail.resize((W, round(rail.height * W / rail.width)), Image.Resampling.LANCZOS)
    ry = round(-rail.height * (1 - ease((t - BARS[0]) / .5)))
    if t >= BARS[0]:
        frame.alpha_composite(rail, (0, ry))

    # Launcher: slides down from under the rail, search typed, Enter on the kick.
    if T_LAUNCH <= t < T_ENTER + .3:
        typed = sum(1 for c in TYPE_TIMES if t >= c)
        panel = load(f'launcher/{max(1, typed):04d}.png') if typed else load('launcher/0001.png')
        if typed == 0:
            panel = load('launcher/0001.png')
        pw = 560 * S
        panel = panel.resize((pw, round(panel.height * pw / panel.width)), Image.Resampling.LANCZOS)
        down = ease((t - T_LAUNCH) / .3) * (1 - ease((t - T_ENTER) / .25))
        py = round(68 * S - (panel.height + 68 * S) * (1 - down))
        cut = max(0, 50 * S - py)
        if cut < panel.height - 1:
            frame.alpha_composite(panel.crop((0, cut, panel.width, panel.height)), ((W - pw) // 2, max(py, 50 * S)))
    # Toast: ghOSt shows notifications top-centre.
    if T_TOAST <= t < T_MEDIA + .2:
        toast = load('toast.png')
        tw = 360 * S
        toast = toast.resize((tw, round(toast.height * tw / toast.width)), Image.Resampling.LANCZOS)
        show = ease((t - T_TOAST) / .3) * (1 - ease((t - T_MEDIA) / .2))
        ty = round(76 * S - 20 * S * (1 - show))
        toast.putalpha(toast.getchannel('A').point(lambda v: round(v * show)))
        frame.alpha_composite(toast, ((W - tw) // 2, ty))
    # Media popup: slides down under the music element; spectrum pulses on the kicks.
    if T_MEDIA <= t < CLOSE[0] + .3:
        hits = [k for k in KICKS if k <= t]
        pulse_index = (len(hits) * 5 + int((t - (hits[-1] if hits else 0)) * 40)) % 24
        media = load(f'media-pulse/{pulse_index:04d}.png')
        mw = 392 * S
        media = media.resize((mw, round(media.height * mw / media.width)), Image.Resampling.LANCZOS)
        down = ease((t - T_MEDIA) / .3)
        gone = clamp((t - CLOSE[0]) / .3)
        my = round(68 * S - (media.height + 68 * S) * (1 - down))
        if gone:
            scale = 1 - .12 * ease(gone)
            media = media.resize((round(mw * scale), round(media.height * scale)), Image.Resampling.BILINEAR)
            media.putalpha(media.getchannel('A').point(lambda v: round(v * (1 - gone))))
        mx = 214 * S + (mw - media.width) // 2
        cut = max(0, 50 * S - my)
        if cut < media.height - 1:
            frame.alpha_composite(media.crop((0, cut, media.width, media.height)), (mx, max(my, 50 * S)))
        # Rail stays above the popup.
        frame.alpha_composite(rail, (0, ry))

    # Camera: slow push-in on the media popup with shallow focus, then back out.
    push = ease_io((t - T_PUSH) / 1.4) * (1 - ease_io((t - (CLOSE[0] - .25)) / .3))
    image = frame
    if push > .002:
        zoom = 1 + .55 * push
        fx, fy = (214 + 196) * S, (68 + 131) * S
        cw, ch = W / zoom, H / zoom
        left = min(W - cw, max(0, fx - cw / 2))
        top = min(H - ch, max(0, fy - ch / 2))
        sharp = frame.resize((W, H), Image.Resampling.BICUBIC, box=(left, top, left + cw, top + ch))
        soft = sharp.resize((W // 4, H // 4), Image.Resampling.BILINEAR).filter(
            ImageFilter.GaussianBlur(5 * push)).resize((W, H), Image.Resampling.BILINEAR)
        # Focus falls off with distance from the popup.
        cx, cy = (fx - left) * zoom, (fy - top) * zoom
        y, x = np.mgrid[0:H:4, 0:W:4].astype(np.float32)
        d = np.sqrt(((x - cx) / (W * .32)) ** 2 + ((y - cy) / (H * .36)) ** 2)
        focus = Image.fromarray((np.clip(1.4 - d, 0, 1) * 255).astype(np.uint8), 'L').resize((W, H))
        image = Image.composite(sharp, soft, focus)
    array = np.asarray(image.convert('RGB')).astype(np.float32)
    array = array * vignette() + grain(0)
    # Gentle grade: lift blacks a touch, soft shoulder on highlights.
    array = 6 + array * .97
    fade = clamp((t - 19.6) / .4)
    if fade:
        array *= (1 - fade * .35)
    return np.clip(array, 0, 255).astype(np.uint8).tobytes()


def _nice():
    import os
    os.nice(10)


def ensure_marks():
    mark = ASSETS / 'ghost-mark.png'
    if not mark.exists():
        subprocess.run(['magick', '-background', 'none', '-density', '1600',
                        str(ROOT / 'config/quickshell/ghost-bar/icons/white/ghost.svg'), '-resize', '1024x1024',
                        str(mark)], check=True)


def preview(times):
    ensure_marks()
    for value in times:
        data = render_frame(round(value * FPS))
        Image.frombytes('RGB', (W, H), data).resize((1920, 1080), Image.Resampling.LANCZOS).save(
            ASSETS / f'showcase-{value:05.2f}.png')


def render(workers=2):
    ensure_marks()
    frames = int(DURATION * FPS)
    # Encode to a temporary name; only a finished file replaces the output.
    partial = OUTPUT.with_name(OUTPUT.stem + '.partial.mp4')
    encoder = subprocess.Popen(
        ['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}', '-r', str(FPS),
         '-i', '-', '-an', '-c:v', 'libx264', '-preset', 'medium',
         # Bounded encoder memory at 4K: fewer threads, shorter look-ahead.
         '-threads', '4', '-x264-params', 'rc-lookahead=12:sync-lookahead=0',
         '-crf', '17', '-pix_fmt', 'yuv420p', str(partial)], stdin=subprocess.PIPE)
    batch = workers * 2
    with Pool(workers, initializer=_nice, maxtasksperchild=200) as pool:
        for start in range(0, frames, batch):
            for data in pool.map(render_frame, range(start, min(frames, start + batch))):
                encoder.stdin.write(data)
            if start % 120 < batch:
                print(f'{start}/{frames}', flush=True)
    encoder.stdin.close()
    if encoder.wait():
        raise SystemExit('ffmpeg failed')
    # Music is added in a separate pass: muxing it live made ffmpeg hold the slow
    # 4K video back for interleaving, which grew memory for the whole render.
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(partial), '-i', str(MUSIC), '-map', '0:v', '-map', '1:a',
                    '-c:v', 'copy', '-c:a', 'aac', '-b:a', '256k', '-shortest', '-movflags', '+faststart', str(OUTPUT)],
                   check=True)
    partial.unlink()
    print('Wrote', OUTPUT)


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'preview':
        preview([float(v) for v in sys.argv[2:]])
    else:
        render()
