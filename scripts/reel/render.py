#!/usr/bin/env python3
"""ghOSt 20-second showreel: beat-locked motion graphics over real component frames.

Every hit is keyed to onsets measured from the soundtrack (kicks and claps), so
cuts, punches and colour flashes land on the music. Frames come from
scripts/reel/capture.py; output goes to .local/reel/ghOSt-showreel.mp4.
"""
from functools import lru_cache
import math
from multiprocessing import Pool
from pathlib import Path
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / '.local/reel'
MUSIC = Path.home() / 'Downloads/mixkit-cbpd-400-20s-drop2.mp3'
OUTPUT = ASSETS / 'ghOSt-showreel.mp4'
W, H, FPS, DURATION = 1920, 1080, 60, 20.0
# Playback speed: 0.85 renders the same reel 15% slower, with the music
# time-stretched to match (pitch kept), so every hit stays on its beat.
SPEED = float(__import__('os').environ.get('GHOST_REEL_SPEED', '1'))

# Measured from the soundtrack (scripts/reel/README.md explains the method).
KICKS = [1.96, 2.58, 3.2, 3.825, 4.86, 5.275, 5.9, 6.52, 7.145, 8.18, 8.595, 9.215, 9.84,
         10.46, 11.495, 11.91, 12.535, 13.155, 13.78, 14.815, 15.23, 15.85, 16.475, 17.095,
         18.135, 18.55, 19.205]
CLAPS = [2.775, 4.43, 6.09, 7.75, 9.41, 11.07, 12.725, 14.385, 16.045, 17.705, 19.37]
BAR = 1.6588
BARS = [1.96 + BAR * index for index in range(12)]

BLACK = (11, 11, 12)
WHITE = (236, 236, 234)
BLUE = (38, 92, 255)
RED = (255, 58, 34)
LIME = (196, 255, 50)
SANS = '/usr/share/fonts/Adwaita/AdwaitaSans-Regular.ttf'
MONO = str(ROOT / 'config/quickshell/ghost-bar/fonts/JetBrainsMono-Regular.ttf')


# ── timing ──────────────────────────────────────────────────────────────────
def last(t, hits):
    previous = [hit for hit in hits if hit <= t + .5 / FPS]
    return previous[-1] if previous else None


def pulse(t, hits, length=.22):
    hit = last(t, hits)
    if hit is None:
        return 0.0
    age = max(0.0, t - hit)
    return math.exp(-age / (length / 3)) if age < length * 2 else 0.0


def count(t, hits, start=0):
    return sum(1 for hit in hits if start - 1e-6 <= hit <= t + .5 / FPS)


def ease(x):
    x = max(0.0, min(1.0, x))
    return 1 - (1 - x) ** 3


def ease_io(x):
    x = max(0.0, min(1.0, x))
    return x * x * (3 - 2 * x)


def since(t, start, length):
    return ease((t - start) / length)


# ── assets ──────────────────────────────────────────────────────────────────
@lru_cache(maxsize=64)
def load(name):
    with Image.open(ASSETS / name if not name.startswith('/') else name) as image:
        return image.convert('RGBA')


@lru_cache(maxsize=256)
def scaled(name, width):
    image = load(name)
    height = max(1, round(image.height * width / image.width))
    return image.resize((width, height), Image.Resampling.LANCZOS)


def seq(folder, index, total):
    return f'{folder}/{max(0, min(total - 1, int(index))):04d}.png'


@lru_cache(maxsize=128)
def xray(name, width, color):
    """Edge-traced 'x-ray' of a frame: luminance edges as glowing lines."""
    image = scaled(name, width)
    rgba = np.asarray(image).astype(np.float32)
    luminance = rgba[..., :3] @ np.array([.299, .587, .114], np.float32)
    alpha = rgba[..., 3] / 255
    gx = np.zeros_like(luminance)
    gy = np.zeros_like(luminance)
    gx[:, 1:-1] = np.abs(luminance[:, 2:] - luminance[:, :-2])
    gy[1:-1, :] = np.abs(luminance[2:, :] - luminance[:-2, :])
    edge = np.clip((gx + gy) / 70, 0, 1) ** .7
    # Outer silhouette edge from alpha, plus a faint body fill.
    ax = np.zeros_like(alpha)
    ax[:, 1:-1] = np.abs(alpha[:, 2:] - alpha[:, :-2])
    ax[1:-1, :] += np.abs(alpha[2:, :] - alpha[:-2, :])
    strength = np.clip(np.maximum(edge * alpha, ax) + alpha * .07, 0, 1)
    out = np.zeros(rgba.shape, np.uint8)
    out[..., :3] = color
    out[..., 3] = (strength * 255).astype(np.uint8)
    return Image.fromarray(out, 'RGBA')


def xray_frame(image, color=RED):
    rgba = np.asarray(image).astype(np.float32)
    luminance = rgba[..., :3] @ np.array([.299, .587, .114], np.float32)
    gx = np.zeros_like(luminance)
    gy = np.zeros_like(luminance)
    gx[:, 1:-1] = np.abs(luminance[:, 2:] - luminance[:, :-2])
    gy[1:-1, :] = np.abs(luminance[2:, :] - luminance[:-2, :])
    edge = np.clip((gx + gy) / 60, 0, 1) ** .7
    out = np.zeros(rgba.shape, np.uint8)
    out[..., :3] = color
    out[..., 3] = (edge * 255).astype(np.uint8)
    return Image.fromarray(out, 'RGBA')


@lru_cache(maxsize=64)
def font(size, weight='Black', mono=False):
    if mono:
        return ImageFont.truetype(MONO, size)
    face = ImageFont.truetype(SANS, size)
    face.set_variation_by_name(weight)
    return face


@lru_cache(maxsize=256)
def text_image(value, size, color, weight='Black', mono=False, tracking=0):
    face = font(size, weight, mono)
    if tracking:
        widths = [face.getlength(ch) + tracking for ch in value]
        width = int(sum(widths)) + 4
    else:
        width = int(face.getlength(value)) + 4
    ascent, descent = face.getmetrics()
    image = Image.new('RGBA', (max(1, width), ascent + descent + 4), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    if tracking:
        x = 0
        for ch in value:
            draw.text((x, 0), ch, font=face, fill=color + (255,))
            x += face.getlength(ch) + tracking
    else:
        draw.text((0, 0), value, font=face, fill=color + (255,))
    return image


def put_text(canvas, value, size, center, color=WHITE, weight='Black', scale=1.0, alpha=1.0,
             mono=False, tracking=0, anchor='center'):
    image = text_image(value, size, color, weight, mono, tracking)
    if abs(scale - 1) > .002:
        image = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))),
                             Image.Resampling.BICUBIC)
    if alpha < 1:
        image = image.copy()
        image.putalpha(image.getchannel('A').point(lambda v: round(v * max(0, alpha))))
    x, y = center
    if anchor == 'center':
        position = (round(x - image.width / 2), round(y - image.height / 2))
    else:
        position = (round(x), round(y - image.height / 2))
    canvas.alpha_composite(image, position)
    return image.size


# ── projection ──────────────────────────────────────────────────────────────
def rotation(yaw, pitch, roll):
    y, p, r = np.radians([yaw, pitch, roll])
    cy, sy, cp, sp, cr, sr = math.cos(y), math.sin(y), math.cos(p), math.sin(p), math.cos(r), math.sin(r)
    return np.array([[cr, -sr, 0], [sr, cr, 0], [0, 0, 1]]) @ np.array(
        [[1, 0, 0], [0, cp, -sp], [0, sp, cp]]) @ np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])


def project(points, center=(960, 540), focal=1800):
    points = np.asarray(points)
    factor = focal / (focal + points[:, 2])
    return np.stack((center[0] + points[:, 0] * factor, center[1] + points[:, 1] * factor), axis=1)


def coefficients(destination, source):
    rows, values = [], []
    for (x, y), (u, v) in zip(destination, source):
        rows.extend([[x, y, 1, 0, 0, 0, -u * x, -u * y], [0, 0, 0, x, y, 1, -v * x, -v * y]])
        values.extend([u, v])
    return np.linalg.solve(np.asarray(rows), np.asarray(values))


def warp(canvas, image, corners, opacity=1.0):
    left, top = np.floor(corners.min(axis=0)).astype(int)
    right, bottom = np.ceil(corners.max(axis=0)).astype(int)
    left, top = max(left, -400), max(top, -400)
    right, bottom = min(right, W + 400), min(bottom, H + 400)
    if right - left < 2 or bottom - top < 2:
        return
    local = corners - [left, top]
    matrix = coefficients(local, [(0, 0), (image.width, 0), (image.width, image.height), (0, image.height)])
    warped = image.transform((right - left, bottom - top), Image.Transform.PERSPECTIVE, matrix,
                             Image.Resampling.BICUBIC)
    if opacity < .999:
        warped.putalpha(warped.getchannel('A').point(lambda v: round(v * max(0, opacity))))
    canvas.alpha_composite(warped, (int(left), int(top)))


def card(canvas, image, width, center, yaw=0, pitch=0, roll=0, z=0, opacity=1.0):
    height = width * image.height / image.width
    corners = np.array([[-width / 2, -height / 2, z], [width / 2, -height / 2, z],
                        [width / 2, height / 2, z], [-width / 2, height / 2, z]])
    corners = corners @ rotation(yaw, pitch, roll).T
    warp(canvas, image, project(corners, center), opacity)


def plate_layer(canvas, image, rect, plate, z, rot, center, opacity=1.0):
    x, y, w, h = rect
    pw, ph = plate
    corners = np.array([[x - pw / 2, y - ph / 2, z], [x + w - pw / 2, y - ph / 2, z],
                        [x + w - pw / 2, y + h - ph / 2, z], [x - pw / 2, y + h - ph / 2, z]], float)
    corners = corners @ rot.T
    points = project(corners, center)
    warp(canvas, image, points, opacity)
    return points


# ── frame-wide effects ──────────────────────────────────────────────────────
@lru_cache(maxsize=4)
def grain(seed):
    rng = np.random.default_rng(seed)
    return (rng.normal(0, 5.5, (H, W, 1))).astype(np.float32)


def finish(canvas, t, zoom=1.0, flash=None, flash_amount=0.0, split=0):
    frame = canvas.convert('RGB')
    if zoom > 1.0015:
        cw, ch = W / zoom, H / zoom
        box = ((W - cw) / 2, (H - ch) / 2, (W + cw) / 2, (H + ch) / 2)
        frame = frame.resize((W, H), Image.Resampling.BILINEAR, box=box)
    array = np.asarray(frame).astype(np.float32)
    if split:
        array[..., 0] = np.roll(array[..., 0], split, axis=1)
        array[..., 2] = np.roll(array[..., 2], -split, axis=1)
    if flash and flash_amount > 0.002:
        array = array * (1 - flash_amount) + np.array(flash, np.float32) * flash_amount
    array += grain(int(t * FPS) % 4)
    return np.clip(array, 0, 255).astype(np.uint8)


def background(color=BLACK):
    return Image.new('RGBA', (W, H), color + (255,))


def dot_field(canvas, t, alpha=26, drift=0.0):
    """Sparse lattice: a quiet engineering backdrop."""
    draw = ImageDraw.Draw(canvas)
    offset = (t * drift) % 48
    for y in range(24, H, 48):
        for x in range(24, W + 48, 48):
            draw.point((x - offset, y), fill=(255, 255, 255, alpha))


def scan_reveal(canvas, real, ray, position, width, band=160):
    """Composite x-ray everywhere, real pixels inside a moving vertical band."""
    if ray.size != real.size:
        ray = ray.resize(real.size, Image.Resampling.BILINEAR)
    rx = np.asarray(ray).copy()
    rr = np.asarray(real)
    x0 = int(position - band)
    x1 = int(position)
    lo, hi = max(0, x0), min(rr.shape[1], x1)
    if hi > lo:
        rx[:, lo:hi] = rr[:, lo:hi]
    out = Image.fromarray(rx, 'RGBA')
    return out


# ── detail layers ───────────────────────────────────────────────────────────
GHOST = 'ghost-mark.png'
OUTLINE = 'ghost-outline.png'
MUTED = (140, 140, 138)

# Feature anchors, in 1× component coordinates (measured from the captures).
RAIL_POINTS = {'menu': (45, 27), 'workspaces': (172, 27), 'music': (410, 27), 'clock': (960, 27),
               'status': (1765, 27), 'power': (1897, 27)}
CAL = (918, 425)
CAL_POINTS = {'forecast': (150, 300), 'weather': (110, 185), 'gauges': (460, 210), 'month': (750, 260),
              'header': (150, 55)}
MEDIA_POINTS = {'art': (58, 90), 'title': (200, 66), 'seek': (196, 156), 'play': (196, 216)}
SIDE_POINTS = {'clock': (70, 75), 'network': (113, 166), 'bluetooth': (300, 166), 'sliders': (209, 437)}


@lru_cache(maxsize=1)
def wallpaper():
    with Image.open(Path.home() / 'Documents/ghostpaper.png') as source:
        return source.convert('RGBA').resize((1920, 1080), Image.Resampling.LANCZOS)


@lru_cache(maxsize=4)
def desktop(kind='rail'):
    """Flat composite of the real desktop: wallpaper, rail and optional panels."""
    plate = wallpaper().copy()
    if kind in ('full', 'panels'):
        plate.alpha_composite(scaled('sidebar/0029.png', 410), (16, 82))
        plate.alpha_composite(scaled('calendar/0045.png', 918), ((1920 - 918) // 2, 82))
        plate.alpha_composite(scaled('media.png', 392), (1450, 68))
    plate.alpha_composite(scaled('rail.png', 1920), (0, 0))
    return plate


@lru_cache(maxsize=6)
def backdrop_image(kind, dim, blur):
    from PIL import ImageFilter
    image = desktop(kind).resize((round(W * 1.12), round(H * 1.12)), Image.Resampling.BILINEAR)
    if blur:
        image = image.filter(ImageFilter.GaussianBlur(blur))
    shade = Image.new('RGBA', image.size, BLACK + (round(255 * dim),))
    image.alpha_composite(shade)
    return image


def backdrop(canvas, t, kind='full', dim=.78, blur=6, drift=1.0):
    image = backdrop_image(kind, dim, blur)
    x = -(image.width - W) / 2 + math.sin(t * .35) * 40 * drift
    y = -(image.height - H) / 2 + math.cos(t * .27) * 22 * drift
    canvas.alpha_composite(image, (round(x), round(y)))


@lru_cache(maxsize=2)
def desktop_xray(color):
    return xray_frame(desktop('full'), color)


def hud(canvas, t, section, color=WHITE):
    """Thin frame, section name, timecode and progress: the engineered layer."""
    draw = ImageDraw.Draw(canvas)
    edge = color + (46,)
    draw.rectangle([36, 36, W - 36, H - 36], outline=edge, width=1)
    put_text(canvas, 'ghOSt / ' + section, 18, (56, 62), color, mono=True, anchor='left', tracking=1)
    seconds = t
    put_text(canvas, f'{int(seconds // 60):02d}:{seconds % 60:05.2f}', 18, (W - 160, 62), color, mono=True,
             anchor='left')
    progress = t / DURATION
    draw.rectangle([36, H - 38, 36 + (W - 72) * progress, H - 36], fill=color + (150,))
    bar = sum(1 for start in BARS if start <= t + .5 / FPS)
    put_text(canvas, f'bar {bar:02d}  144 bpm', 18, (56, H - 62), color, mono=True, anchor='left', alpha=.55)


def callout(canvas, t, start, anchor, label, sub='', dx=120, dy=-60, color=WHITE):
    """A dot on a real feature, a leader line drawn in, then its label."""
    if t < start:
        return
    grow = ease((t - start) / .22)
    draw = ImageDraw.Draw(canvas)
    ax, ay = anchor
    ex, ey = ax + dx * min(1, grow * 1.6), ay + dy * min(1, grow * 1.6)
    draw.ellipse([ax - 5, ay - 5, ax + 5, ay + 5], fill=color + (255,))
    draw.ellipse([ax - 11, ay - 11, ax + 11, ay + 11], outline=color + (120,), width=1)
    draw.line([(ax, ay), (ex, ey)], fill=color + (220,), width=2)
    if grow > .55:
        length = 30 + 0 * len(label)
        direction = 1 if dx >= 0 else -1
        tx = ex + direction * length * ease((grow - .55) / .45)
        draw.line([(ex, ey), (tx, ey)], fill=color + (220,), width=2)
        alpha = ease((grow - .6) / .4)
        title = text_image(label, 30, color, 'Bold')
        note = text_image(sub, 19, MUTED, 'Black', True) if sub else None
        span = max(title.width, note.width if note else 0)
        lx = tx + 12 if direction > 0 else tx - 12 - span
        lx = min(W - 60 - span, max(60, lx))
        put_text(canvas, label, 30, (lx, ey - 6), color, weight='Bold', anchor='left', alpha=alpha)
        if sub:
            put_text(canvas, sub, 19, (lx + 1, ey + 26), MUTED, mono=True, anchor='left', alpha=alpha)


def lens(canvas, t, start, image, box, center, width, label='', color=WHITE):
    """Magnified crop of a real component, popping in on a hit."""
    if t < start:
        return
    pop = ease((t - start) / .2)
    x0, y0, x1, y1 = box
    crop = image.crop((round(x0), round(y0), round(x1), round(y1)))
    height = round(width * crop.height / crop.width)
    scale = .7 + .3 * pop
    w, h = max(2, round(width * scale)), max(2, round(height * scale))
    zoomed = crop.resize((w, h), Image.Resampling.LANCZOS)
    frame = Image.new('RGBA', (w + 12, h + 12), (0, 0, 0, 0))
    mask = Image.new('L', (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, h - 1], 14, fill=255)
    tile = Image.new('RGBA', (w, h), (12, 12, 13, 255))
    tile.alpha_composite(zoomed)
    frame.paste(tile, (6, 6), mask)
    ImageDraw.Draw(frame).rounded_rectangle([5, 5, w + 6, h + 6], 15, outline=color + (230,), width=2)
    if pop < 1:
        frame.putalpha(frame.getchannel('A').point(lambda v: round(v * pop)))
    cx, cy = center
    canvas.alpha_composite(frame, (round(cx - frame.width / 2), round(cy - frame.height / 2)))
    if label:
        put_text(canvas, label, 20, (cx - frame.width / 2 + 6, cy + frame.height / 2 + 24), color, mono=True,
                 anchor='left', alpha=pop, tracking=1)


@lru_cache(maxsize=1)
def commits():
    output = subprocess.run(['git', '-C', str(ROOT), 'log', '--format=%s', '-n', '60'],
                            capture_output=True, text=True).stdout.splitlines()
    return [line[:70] for line in output if line.strip()]


def commit_wall(canvas, t, color, alpha=70):
    lines = commits()
    offset = (t * 90) % 44
    for row in range(-1, 27):
        text = lines[(row + int(t * 90 // 44)) % len(lines)]
        put_text(canvas, text, 22, (80 + (row % 3) * 620, 40 + row * 44 - offset), color, mono=True,
                 anchor='left', alpha=alpha / 255)


# ── scenes ──────────────────────────────────────────────────────────────────
def intro(t):
    canvas = background()
    ray = desktop_xray((90, 90, 92))
    scan = 1920 * ease_io(t / 1.9)
    layer = ray.copy()
    layer.putalpha(layer.getchannel('A').point(lambda v: round(v * .55)))
    canvas.alpha_composite(layer)
    draw = ImageDraw.Draw(canvas)
    draw.rectangle([scan - 2, 0, scan + 2, H], fill=BLUE + (170,))
    draw.rectangle([0, 470, W, 610], fill=BLACK + (235,))
    line = 'every rice looks the same.'
    shown = line[:int(len(line) * ease_io((t - .15) / .9))]
    if shown:
        put_text(canvas, shown, 54, (960, 540), WHITE, mono=True, alpha=1 - since(t, 1.25, .25))
    if t > 1.15:
        grow = ease((t - 1.15) / .8)
        card(canvas, xray(OUTLINE, 520, WHITE), 360 + 260 * grow, (960, 540), roll=-8 * (1 - grow), opacity=grow)
    zoom = 1 + .06 * ease_io((t - 1.2) / .76)
    whiteout = max(0.0, (t - 1.70) / .26)
    return finish(canvas, t, zoom, WHITE, min(1, whiteout) * .45)


@lru_cache(maxsize=1)
def _dark_mark():
    image = scaled(GHOST, 260).copy()
    array = np.asarray(image).copy()
    array[..., :3] = 255 - array[..., :3]
    return Image.fromarray(array, 'RGBA')


def identity(t):
    inverted = count(t, KICKS[1:2]) % 2 == 1
    blue = t >= CLAPS[0]
    bg = BLUE if blue else (BLACK if inverted else WHITE)
    fg = WHITE if (inverted or blue) else BLACK
    canvas = background(bg)
    # A faint x-ray of the real desktop drifts behind the wordmark.
    ray = desktop_xray(fg)
    layer = ray.resize((round(W * 1.25), round(H * 1.25)), Image.Resampling.BILINEAR)
    layer.putalpha(layer.getchannel('A').point(lambda v: round(v * .22)))
    canvas.alpha_composite(layer, (round(-200 - (t - BARS[0]) * 60), -130))
    punch = pulse(t, KICKS[:4] + CLAPS[:1], .3)
    mark = scaled(GHOST, 260) if fg == WHITE else _dark_mark()
    words = 'is here.' if t >= KICKS[2] else 'ghOSt'
    put_text(canvas, words, 300, (1040, 520), fg, scale=1 + .22 * punch)
    if t < KICKS[2]:
        canvas.alpha_composite(mark, (160, 520 - mark.height // 2 - 10))
    if t >= CLAPS[0]:
        put_text(canvas, 'a desktop shell for Hyprland', 44, (1040, 760), fg, weight='Medium',
                 alpha=since(t, CLAPS[0], .12))
        put_text(canvas, 'built in QML on Quickshell', 22, (1040, 830), fg, mono=True, alpha=.7 * since(t, CLAPS[0], .2))
    split = int(14 * pulse(t, KICKS[:1], .25))
    return finish(canvas, t, 1 + .05 * punch, BLACK, .0, split)


LAYERS = [
    ('wallpaper', (0, 0, 1920, 1080), 'your image, untouched'),
    ('sidebar', (16, 82, 410, 914), 'network  bluetooth  sound'),
    ('calendar', ((1920 - 918) // 2, 82, 918, 425), 'weather  system  month'),
    ('media', (1450, 68, 392, 262), 'now playing'),
    ('rail', (0, 0, 1920, 50), 'workspaces  music  clock'),
]


def layer_image(name, width, ray=False, color=BLUE):
    source = {'sidebar': 'sidebar/0029.png', 'calendar': 'calendar/0045.png', 'media': 'media.png',
              'rail': 'rail.png'}.get(name)
    if name == 'wallpaper':
        if ray:
            return Image.new('RGBA', (width, round(width * 1080 / 1920)), color + (14,))
        return wallpaper().resize((width, round(width * 1080 / 1920)), Image.Resampling.BILINEAR)
    return xray(source, width, color) if ray else scaled(source, width)


def xray_stack(t):
    canvas = background()
    dot_field(canvas, t, alpha=22, drift=-20)
    tilt = since(t, KICKS[3], .35)
    explode = since(t, KICKS[4], .45)
    ray_on = t >= CLAPS[1]
    accent = BLUE if t < CLAPS[2] else LIME
    yaw = -24 * tilt + 5 * since(t, KICKS[6], .5) - 5 * since(t, KICKS[7], .5)
    rot = rotation(yaw, 50 * tilt, 24 * tilt)
    scale = 1 - .42 * tilt
    separation = 130 * explode
    pw, ph = 1920 * scale, 1080 * scale
    probe = []
    for depth in (0, len(LAYERS) - 1):
        corners = np.array([[-pw / 2, -ph / 2, -depth * separation], [pw / 2, -ph / 2, -depth * separation],
                            [pw / 2, ph / 2, -depth * separation], [-pw / 2, ph / 2, -depth * separation]])
        probe.append(project(corners @ rot.T, (0, 0)))
    probe = np.concatenate(probe)
    middle = (probe.min(axis=0) + probe.max(axis=0)) / 2
    center = (960 - middle[0], 470 - middle[1])
    labels = []
    band_x = -200 + 2600 * ease_io((t - CLAPS[1]) / .9) if ray_on else -9999
    for depth, (name, rect, sub) in enumerate(LAYERS):
        x, y, w, h = rect
        rect = (x * scale, y * scale, w * scale, h * scale)
        z = -depth * separation
        width = max(8, round(rect[2]))
        real = layer_image(name, width)
        if ray_on:
            ray = layer_image(name, width, ray=True, color=accent)
            points = plate_layer(canvas, ray, rect, (pw, ph), z, rot, center)
            if points[:, 0].min() - 200 < band_x < points[:, 0].max() + 260:
                fraction = (band_x - points[:, 0].min()) / max(1, points[:, 0].max() - points[:, 0].min())
                cut = scan_reveal(canvas, real, ray, fraction * real.width, real.width, band=real.width * .22)
                plate_layer(canvas, cut, rect, (pw, ph), z, rot, center)
        else:
            points = plate_layer(canvas, real, rect, (pw, ph), z, rot, center)
        labels.append((name, sub, points))
    if explode > .6:
        reveal = {'rail': KICKS[4] + .3, 'calendar': KICKS[5], 'sidebar': KICKS[6], 'media': KICKS[7],
                  'wallpaper': KICKS[7] + .2}
        for name, sub, points in labels:
            anchor = tuple(points.mean(axis=0))
            left = anchor[0] < 960
            callout(canvas, t, reveal[name], anchor, name, sub, dx=-140 if left else 140,
                    dy=-70 if name != 'wallpaper' else 60, color=accent if t >= CLAPS[2] else WHITE)
    if t >= CLAPS[2]:
        put_text(canvas, 'every layer, designed.', 92, (960, 975), WHITE, scale=1 + .12 * pulse(t, CLAPS[2:3], .3))
    elif t < KICKS[3] + .15:
        put_text(canvas, 'look closer.', 92, (960, 975), WHITE, alpha=1 - since(t, KICKS[3], .15))
    hud(canvas, t, 'layers')
    zoom = 1 + .035 * pulse(t, KICKS[3:8] + CLAPS[1:3], .25)
    flash = max(pulse(t, CLAPS[1:3], .14), .6 * pulse(t, [KICKS[4]], .1), .3 * pulse(t, KICKS[5:8], .1))
    return finish(canvas, t, zoom, accent, .55 * flash)


def rail_scene(t):
    canvas = background()
    backdrop(canvas, t, 'rail', dim=.82)
    wheel_index = (t - BARS[3]) / 1.4 * 39
    live = load(seq('wheel', wheel_index, 40))
    strip = live.resize((1760, round(live.height * 1760 / live.width)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(strip, (80, 150))
    k = 1760 / 1920
    point = lambda name: (80 + RAIL_POINTS[name][0] * k, 150 + RAIL_POINTS[name][1] * k)
    # Three magnifiers, one per hit, each with what the element does.
    s = live.width / 1920
    lens(canvas, t, KICKS[8], live, (95 * s, 0, 260 * s, live.height), (380, 470), 520, 'workspace wheel')
    lens(canvas, t, CLAPS[3], live, (860 * s, 0, 1060 * s, live.height), (960, 470), 520, 'clock', RED)
    lens(canvas, t, KICKS[9], live, (1660 * s, 0, 1910 * s, live.height), (1540, 470), 520, 'status')
    draw = ImageDraw.Draw(canvas)
    for hit, name, target in ((KICKS[8], 'workspaces', (380, 400)), (CLAPS[3], 'clock', (960, 400)),
                              (KICKS[9], 'status', (1540, 400))):
        if t >= hit:
            grow = ease((t - hit) / .2)
            ax, ay = point(name)
            draw.line([(ax, ay + 20), (ax + (target[0] - ax) * grow, ay + 20 + (target[1] - ay - 20) * grow)],
                      fill=(RED if name == 'clock' else WHITE) + (200,), width=2)
    put_text(canvas, 'scroll to switch desktops', 22, (380, 610), MUTED, mono=True, alpha=since(t, KICKS[8], .2))
    put_text(canvas, 'opens the calendar', 22, (960, 610), MUTED, mono=True, alpha=since(t, CLAPS[3], .2))
    put_text(canvas, 'wi-fi  bluetooth  battery', 22, (1540, 610), MUTED, mono=True, alpha=since(t, KICKS[9], .2))
    put_text(canvas, 'detailed down to', 64, (960, 790), WHITE, weight='Bold')
    put_text(canvas, 'the pixel.', 150, (960, 900), WHITE, scale=1 + .15 * pulse(t, [CLAPS[3]], .3))
    hud(canvas, t, 'rail')
    zoom = 1 + .04 * pulse(t, [KICKS[8], KICKS[9]], .25)
    return finish(canvas, t, zoom, RED, .5 * pulse(t, [CLAPS[3]], .12))


def calendar_scene(t):
    canvas = background()
    backdrop(canvas, t, 'rail', dim=.84)
    local = t - BARS[4]
    frame = local / .9 * 45
    real = load(seq('calendar', frame, 46))
    width = 1180 + 50 * pulse(t, KICKS[10:13], .3)
    image = real.resize((round(width), round(width * real.height / real.width)), Image.Resampling.LANCZOS)
    if t >= CLAPS[4]:
        sweep = (t - CLAPS[4]) / .55
        ray = xray(seq('calendar', 45, 46), image.width, RED)
        image = scan_reveal(canvas, image, ray, (1 - ease_io(sweep)) * (image.width + 400), image.width,
                            band=image.width * 1.5)
    left, top = 90, 150
    canvas.alpha_composite(image, (left, top))
    k = image.width / CAL[0]
    at = lambda name: (left + CAL_POINTS[name][0] * k, top + CAL_POINTS[name][1] * k)
    callout(canvas, t, KICKS[11], at('forecast'), 'forecast', 'scroll through the week', dx=40, dy=330)
    callout(canvas, t, KICKS[12], at('month'), 'month', 'click the clock to open', dx=40, dy=300)
    # Live readouts counting up beside the calendar.
    readings = [('GPU', 12, 52), ('MEMORY', 30, 54), ('CPU', 18, 48)]
    for index, (label, low, high) in enumerate(readings):
        hit = [KICKS[10], KICKS[11], KICKS[12]][index]
        if t < hit:
            continue
        value = round(low + (high - low) * ease((t - hit) / .5))
        y = 190 + index * 200
        put_text(canvas, label, 22, (1430, y), MUTED, mono=True, anchor='left', tracking=2)
        put_text(canvas, f'{value}%', 120, (1424, y + 80), RED if t >= CLAPS[4] else WHITE, mono=True, anchor='left',
                 scale=1 + .1 * pulse(t, [hit], .25))
    put_text(canvas, 'useful at a glance.', 110, (960, 960), WHITE, scale=1 + .14 * pulse(t, [CLAPS[4]], .3),
             alpha=since(t, CLAPS[4], .08))
    hud(canvas, t, 'calendar')
    zoom = 1 + .03 * pulse(t, KICKS[10:13], .25)
    return finish(canvas, t, zoom, RED, .5 * pulse(t, [CLAPS[4]], .12))


def media_sidebar(t):
    canvas = background()
    backdrop(canvas, t, 'rail', dim=.7, blur=0, drift=.3)
    # Real rail on top, as on the desktop.
    canvas.alpha_composite(scaled('rail.png', 1920), (0, 0))
    media = scaled('media.png', 640)
    drop = since(t, KICKS[13], .32)
    mx, my = 1020, round(-media.height * .45 + (media.height * .45 + 120) * drop)
    canvas.alpha_composite(media, (mx, my))
    k = 640 / 392
    at = lambda name: (mx + MEDIA_POINTS[name][0] * k, my + MEDIA_POINTS[name][1] * k)
    if drop > .9:
        callout(canvas, t, KICKS[13] + .2, at('art'), 'artwork', 'or a live spectrum', dx=-40, dy=520)
        callout(canvas, t, KICKS[13] + .32, at('seek'), 'seek', 'click anywhere on the bar', dx=190, dy=210)
    if t >= CLAPS[5]:
        side = load(seq('sidebar', min(29, (t - CLAPS[5]) / .45 * 29), 30))
        sw = 470
        image = side.resize((sw, round(side.height * sw / side.width)), Image.Resampling.LANCZOS)
        sx = round(-sw + (sw + 40) * since(t, CLAPS[5], .3))
        canvas.alpha_composite(image, (sx, 110))
        ks = sw / 410
        callout(canvas, t, CLAPS[5] + .25, (sx + SIDE_POINTS['network'][0] * ks, 110 + SIDE_POINTS['network'][1] * ks),
                'wi-fi and bluetooth', 'connect in one click', dx=430, dy=110)
        callout(canvas, t, KICKS[14], (sx + SIDE_POINTS['sliders'][0] * ks, 110 + SIDE_POINTS['sliders'][1] * ks),
                'volume and brightness', 'drag or scroll', dx=360, dy=250)
    put_text(canvas, 'built for every day.', 104, (1290, 990), WHITE,
             scale=1 + .12 * pulse(t, [CLAPS[5], KICKS[14]], .3), alpha=since(t, CLAPS[5], .1))
    hud(canvas, t, 'media + sidebar')
    zoom = 1 + .035 * pulse(t, [KICKS[13], KICKS[14]], .25)
    return finish(canvas, t, zoom, BLUE, max(.5 * pulse(t, [CLAPS[5]], .12), .3 * pulse(t, [KICKS[13]], .1)))


SETTINGS = ['general', 'applications', 'bluetooth', 'sound', 'about']
WALL = ['network', 'brightness', 'notifications', 'battery', 'storage', 'accessibility', 'general', 'sound',
        'about']


def settings_scene(t):
    hits = [KICKS[15], KICKS[16], CLAPS[6], KICKS[17], BARS[7] - .3]
    index = max(0, count(t, hits) - 1)
    on_clap = index == 2 and t - CLAPS[6] < .1
    canvas = background(LIME if on_clap else BLACK)
    # A wall of real pages in x-ray, drifting behind.
    drift = (t - BARS[6]) * 70
    for i, page in enumerate(WALL):
        col, row = i % 3, i // 3
        ray = xray(f'settings-{page}.png', 560, LIME if index >= 2 else (120, 120, 120))
        card(canvas, ray, 560, (360 + col * 600 - drift, 230 + row * 330), yaw=-14, pitch=10, opacity=.55)
    name = SETTINGS[min(index, len(SETTINGS) - 1)]
    image = scaled(f'settings-{name}.png', 1040)
    age = t - (last(t, hits) or BARS[6])
    slide = 1 - ease(age / .22)
    card(canvas, image, 1040, (960 + 180 * slide * (1 if index % 2 else -1), 500), yaw=-8 + 4 * (index % 3), pitch=6)
    chip = text_image(name, 26, BLACK, 'Bold')
    chip_box = Image.new('RGBA', (chip.width + 36, 48), LIME + (255,))
    chip_box.alpha_composite(chip, (18, 6))
    canvas.alpha_composite(chip_box, (430, 92))
    if name == 'applications':
        put_text(canvas, 'drag to rearrange the top bar', 24, (1050, 116), WHITE, mono=True, anchor='left')
    put_text(canvas, '14 pages of settings.', 104, (960, 960), WHITE, scale=1 + .1 * pulse(t, hits, .25))
    put_text(canvas, 'every option, one place.', 40, (960, 1035), WHITE, weight='Medium', alpha=since(t, CLAPS[6], .12))
    hud(canvas, t, 'settings', LIME if index >= 2 else WHITE)
    zoom = 1 + .03 * pulse(t, hits, .22)
    return finish(canvas, t, zoom, LIME, .45 * pulse(t, [CLAPS[6]], .12))


def motion_scene(t):
    canvas = background()
    backdrop(canvas, t, 'rail', dim=.86)
    local = t - BARS[7]
    cycle = (local % .83) / .83
    for echo in range(6, -1, -1):
        phase = max(0.0, cycle - echo * .05)
        name = seq('sidebar', phase * 29, 30)
        x = 300 + 260 * ease(phase)
        if echo:
            card(canvas, xray(name, 360, BLUE if echo % 2 else WHITE), 360, (x, 500), yaw=18, opacity=.5 - echo * .06)
        else:
            card(canvas, load(name), 360, (x, 500), yaw=18)
    hit = last(t, [BARS[7], KICKS[18], CLAPS[7], KICKS[19]]) or BARS[7]
    card(canvas, load(seq('calendar', (t - hit) / .5 * 45, 46)), 820, (1300, 430), yaw=-16, pitch=4)
    # Frame-time trace: measured ~5.1 ms per frame at 200 Hz.
    draw = ImageDraw.Draw(canvas)
    x0, y0, gw, gh = 760, 760, 1060, 70
    draw.line([(x0, y0 + gh), (x0 + gw, y0 + gh)], fill=(255, 255, 255, 60), width=1)
    rng = np.random.default_rng(3)
    jitter = rng.normal(0, .18, 400)
    points = []
    for i in range(160):
        sample = (i + int(local * 120)) % 400
        value = 5.1 + jitter[sample]
        points.append((x0 + i * gw / 159, y0 + gh - (value / 10) * gh))
    draw.line(points, fill=BLUE + (255,), width=2)
    put_text(canvas, '5.1 ms / frame', 22, (x0, y0 - 18), BLUE, mono=True, anchor='left')
    put_text(canvas, 'motion that feels right.', 96, (1240, 900), WHITE,
             scale=1 + .12 * pulse(t, [CLAPS[7]], .3), alpha=since(t, KICKS[18], .12))
    put_text(canvas, 'smooth at 200 Hz.', 38, (1240, 985), WHITE, weight='Medium', alpha=since(t, CLAPS[7], .12))
    hud(canvas, t, 'motion')
    zoom = 1 + .035 * pulse(t, [KICKS[18], KICKS[19], CLAPS[7]], .25)
    return finish(canvas, t, zoom, BLUE, max(.5 * pulse(t, [CLAPS[7]], .12), .3 * pulse(t, [KICKS[18], KICKS[19]], .1)))


SDDM_POINTS = {'password': (450, 731), 'keyboard': (259, 1011), 'session': (330, 1011), 'power': (1837, 1011)}


def login_scene(t):
    canvas = background()
    login = load(str(ROOT / 'config/sddm/ghost/preview.png'))
    local = t - BARS[8]
    scale = 1.25 - .25 * ease(local / 1.4)
    width = round(W * scale)
    image = login.resize((width, round(width * 1080 / 1920)), Image.Resampling.BILINEAR)
    x = round(W / 2 - width * .42)
    y = round(H / 2 - image.height * .55)
    canvas.alpha_composite(image, (x, y))
    dots = count(t, [KICKS[20], KICKS[21], CLAPS[8], KICKS[22]]) * 3
    draw = ImageDraw.Draw(canvas)
    fx, fy = x + 258 * scale, y + 731 * scale
    for i in range(min(12, dots)):
        r = 5 * scale
        draw.ellipse([fx + i * 16 * scale - r, fy - r, fx + i * 16 * scale + r, fy + r], fill=WHITE + (255,))
    at = lambda name: (x + SDDM_POINTS[name][0] * scale, y + SDDM_POINTS[name][1] * scale)
    callout(canvas, t, KICKS[21], at('keyboard'), 'keyboard on demand', '', dx=60, dy=-150)
    callout(canvas, t, KICKS[22], at('session'), 'pick your session', '', dx=260, dy=-90)
    if t >= CLAPS[8]:
        sweep = ease_io((t - CLAPS[8]) / .5)
        layer = canvas.crop((0, 0, W, H))
        ray = Image.new('RGBA', (W, H), BLACK + (255,))
        ray.alpha_composite(xray_frame(layer))
        canvas = scan_reveal(canvas, layer, ray, W * (1 - sweep) + 300, W, band=W * 1.2)
    put_text(canvas, 'from login', 120, (1420, 380), WHITE, scale=1 + .1 * pulse(t, [KICKS[20]], .3))
    put_text(canvas, 'to lock screen.', 120, (1420, 510), WHITE, alpha=since(t, CLAPS[8], .1),
             scale=1 + .12 * pulse(t, [CLAPS[8]], .3))
    put_text(canvas, 'its own SDDM theme, same design', 26, (1420, 610), MUTED, mono=True, alpha=since(t, CLAPS[8], .2))
    hud(canvas, t, 'login')
    zoom = 1 + .03 * pulse(t, [KICKS[20], KICKS[21], KICKS[22]], .25)
    return finish(canvas, t, zoom, RED, .5 * pulse(t, [CLAPS[8]], .12))


def open_scene(t):
    hits = [BARS[9], KICKS[23], CLAPS[9], KICKS[24]]
    step = max(0, count(t, hits) - 1)
    palette = [(BLACK, WHITE), (WHITE, BLACK), (LIME, BLACK), (BLUE, WHITE)][step]
    canvas = background(palette[0])
    # Real commit history of the project scrolling behind.
    commit_wall(canvas, t, palette[1], alpha=46)
    words = ['created by', 'me.', 'and you.', 'open source.'][step]
    size = [120, 300, 300, 230][step]
    plate = Image.new('RGBA', (W, 380), palette[0] + (220,))
    canvas.alpha_composite(plate, (0, 310))
    put_text(canvas, words, size, (960, 500), palette[1], scale=1 + .2 * pulse(t, hits, .3))
    if step >= 1:
        put_text(canvas, 'every commit is public. bring your ideas.', 38, (960, 760), palette[1], weight='Medium')
    zoom = 1 + .05 * pulse(t, hits, .25)
    return finish(canvas, t, zoom, WHITE, .35 * pulse(t, hits[1:], .1), int(10 * pulse(t, hits[1:], .15)))


def finale(t):
    canvas = background()
    ray = desktop_xray((70, 70, 72)).copy()
    ray.putalpha(ray.getchannel('A').point(lambda v: round(v * .5)))
    canvas.alpha_composite(ray)
    local = t - BARS[10]
    mark = scaled(GHOST, round(300 + 40 * pulse(t, [KICKS[25], KICKS[26]], .3)))
    canvas.alpha_composite(mark, (960 - mark.width // 2, 360 - mark.height // 2))
    put_text(canvas, 'ghOSt', 200, (960, 640), WHITE, scale=1 + .1 * pulse(t, [KICKS[26]], .3))
    features = 'rail   calendar   sidebar   media   settings   lock   login'
    put_text(canvas, features, 24, (960, 770), MUTED, mono=True, alpha=since(t, KICKS[26], .2))
    if t >= CLAPS[10]:
        put_text(canvas, 'github.com/dsksnkz/ghOSt', 40, (960, 850), WHITE, mono=True,
                 scale=1 + .25 * pulse(t, [CLAPS[10]], .3))
    if local < .5:
        card(canvas, xray(OUTLINE, 900, WHITE), 900 + 600 * ease(local / .5), (960, 420), opacity=1 - local / .5)
    fade = max(0.0, (t - 19.55) / .45)
    if fade <= 0 and pulse(t, [CLAPS[10]], .1) > .05:
        return finish(canvas, t, 1 + .04 * pulse(t, [CLAPS[10]], .25), WHITE, .35 * pulse(t, [CLAPS[10]], .1))
    return finish(canvas, t, 1 + .03 * pulse(t, [KICKS[25], KICKS[26]], .25), BLACK, min(1, fade))


SCENES = [(0, intro), (BARS[0], identity), (BARS[1], xray_stack), (BARS[3], rail_scene),
          (BARS[4], calendar_scene), (BARS[5], media_sidebar), (BARS[6], settings_scene),
          (BARS[7], motion_scene), (BARS[8], login_scene), (BARS[9], open_scene), (BARS[10], finale)]


def render_frame(index):
    t = min(DURATION - .5 / FPS, index / FPS * SPEED)
    scene = [function for start, function in SCENES if t >= start - 1e-6][-1]
    return scene(t).tobytes()


def prepare_marks():
    subprocess.run(['magick', '-background', 'none', '-density', '1600',
                    str(ROOT / 'config/quickshell/ghost-bar/icons/white/ghost.svg'),
                    '-resize', '1024x1024', str(ASSETS / GHOST)], check=True)
    subprocess.run(['magick', '-background', 'none', '-density', '200',
                    str(ROOT / 'config/sddm/ghost/assets/ghost-outline.svg'),
                    '-resize', '1400x1400', str(ASSETS / OUTLINE)], check=True)


def preview(times):
    prepare_marks()
    for t in times:
        Image.frombytes('RGB', (W, H), render_frame(round(t * FPS))).save(ASSETS / f'preview-{t:05.2f}.png')


def _lower_priority():
    import os
    os.nice(10)


def render(workers=3):
    prepare_marks()
    frames = round(DURATION / SPEED * FPS)
    output = OUTPUT if SPEED == 1 else OUTPUT.with_name(f'ghOSt-showreel-{round(SPEED * 100)}.mp4')
    # atempo pulls drum attacks ~14 ms early; the delay re-centres them (measured at 0.85).
    audio = [] if SPEED == 1 else ['-af', f'atempo={SPEED},adelay=14:all=1']
    encoder = subprocess.Popen(
        ['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}',
         '-r', str(FPS), '-i', '-', '-i', str(MUSIC), '-map', '0:v', '-map', '1:a',
         '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-pix_fmt', 'yuv420p',
         *audio, '-c:a', 'aac', '-b:a', '256k', '-shortest', '-movflags', '+faststart', str(output)],
        stdin=subprocess.PIPE)
    with Pool(workers, initializer=_lower_priority) as pool:
        for done, data in enumerate(pool.imap(render_frame, range(frames), chunksize=4)):
            encoder.stdin.write(data)
            if done % 120 == 0:
                print(f'{done}/{frames}', flush=True)
    encoder.stdin.close()
    if encoder.wait():
        raise SystemExit('ffmpeg failed')
    print('Wrote', output)


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'preview':
        preview([float(value) for value in sys.argv[2:]])
    else:
        render()
