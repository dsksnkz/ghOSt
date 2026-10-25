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


# ── scenes ──────────────────────────────────────────────────────────────────
GHOST = 'ghost-mark.png'
OUTLINE = 'ghost-outline.png'


def intro(t):
    canvas = background()
    dot_field(canvas, t, alpha=int(18 + 20 * ease(t / 1.9)), drift=30)
    # Mono statement, typed out.
    line = 'every rice looks the same.'
    shown = line[:int(len(line) * ease_io((t - .15) / .9))]
    if shown:
        put_text(canvas, shown, 54, (960, 540), WHITE, mono=True, alpha=1 - since(t, 1.25, .25))
    # The ghost appears in x-ray, scanning, as the build rises.
    if t > 1.15:
        grow = ease((t - 1.15) / .8)
        ray = xray(OUTLINE, 520, WHITE)
        card(canvas, ray, 360 + 260 * grow, (960, 540), roll=-8 * (1 - grow), opacity=grow)
        if t > 1.5:
            band = 960 - 300 + 600 * ease((t - 1.5) / .45)
            draw = ImageDraw.Draw(canvas)
            draw.rectangle([band - 2, 0, band + 2, H], fill=BLUE + (int(200 * grow),))
    zoom = 1 + .06 * ease_io((t - 1.2) / .76)
    whiteout = max(0.0, (t - 1.70) / .26)
    return finish(canvas, t, zoom, WHITE, min(1, whiteout) * .45)


def identity(t):
    start = BARS[0]
    inverted = count(t, KICKS[1:2]) % 2 == 1
    blue = t >= CLAPS[0]
    bg = BLUE if blue else (BLACK if inverted else WHITE)
    fg = WHITE if (inverted or blue) else BLACK
    canvas = background(bg)
    if not blue:
        dot_field(canvas, t, alpha=20)
    punch = pulse(t, KICKS[:4] + CLAPS[:1], .3)
    mark = scaled(GHOST, 260) if fg == WHITE else _dark_mark()
    words = 'ghOSt'
    if t >= KICKS[2]:
        words = 'is here.'
    size = 300
    put_text(canvas, words, size, (1040, 520), fg, scale=1 + .22 * punch)
    if t < KICKS[2]:
        canvas.alpha_composite(mark, (160, 520 - mark.height // 2 - 10))
    sub = 'a desktop shell for Hyprland' if t >= CLAPS[0] else ''
    if sub:
        put_text(canvas, sub, 40, (1040, 760), fg, weight='Medium', alpha=since(t, CLAPS[0], .12))
    split = int(14 * pulse(t, KICKS[:1], .25))
    zoom = 1 + .05 * punch
    return finish(canvas, t, zoom, BLACK, .0, split)


@lru_cache(maxsize=1)
def _dark_mark():
    image = scaled(GHOST, 260).copy()
    array = np.asarray(image).copy()
    array[..., :3] = 255 - array[..., :3]
    return Image.fromarray(array, 'RGBA')


# Desktop plate geometry (1920 × 1080 design space).
PLATE = (1920, 1080)
LAYERS = [
    ('wallpaper', (0, 0, 1920, 1080)),
    ('sidebar', (16, 82, 410, 914)),
    ('calendar', ((1920 - 918) // 2, 82, 918, 425)),
    ('media', (1450, 68, 392, 262)),
    ('rail', (0, 0, 1920, 50)),
]


@lru_cache(maxsize=1)
def wallpaper():
    with Image.open(Path.home() / 'Documents/ghostpaper.png') as source:
        image = source.convert('RGBA').resize((1920, 1080), Image.Resampling.LANCZOS)
    return image


def layer_image(name, width, ray=False, color=BLUE):
    source = {'sidebar': 'sidebar/0029.png', 'calendar': 'calendar/0045.png', 'media': 'media.png',
              'rail': 'rail.png'}.get(name)
    if name == 'wallpaper':
        if ray:
            return Image.new('RGBA', (width, round(width * 1080 / 1920)), color + (14,))
        return wallpaper().resize((width, round(width * 1080 / 1920)), Image.Resampling.BILINEAR)
    return xray(source, width, color) if ray else scaled(source, width)


def xray_stack(t):
    start = BARS[1]
    canvas = background()
    dot_field(canvas, t, alpha=22, drift=-20)
    tilt = since(t, KICKS[3], .35)
    explode = since(t, KICKS[4], .45)
    ray_on = t >= CLAPS[1]
    yaw = -24 * tilt + 5 * since(t, KICKS[6], .5) - 5 * since(t, KICKS[7], .5)
    pitch = 50 * tilt
    roll = 24 * tilt
    rot = rotation(yaw, pitch, roll)
    scale = 1 - .42 * tilt
    separation = 130 * explode
    # Keep the whole projected stack centred in the frame.
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
    for depth, (name, rect) in enumerate(LAYERS):
        x, y, w, h = rect
        rect = (x * scale, y * scale, w * scale, h * scale)
        plate = (pw, ph)
        z = -depth * separation
        width = max(8, round(rect[2]))
        real = layer_image(name, width)
        if ray_on:
            ray = layer_image(name, width, ray=True, color=BLUE if t < CLAPS[2] else LIME)
            # Real pixels show only where the scan band passes (in projected x).
            points = plate_layer(canvas, ray, rect, plate, z, rot, center)
            if band_x > points[:, 0].min() - 200 and band_x < points[:, 0].max() + 260:
                local = band_x - points[:, 0].min()
                fraction = local / max(1, points[:, 0].max() - points[:, 0].min())
                cut = scan_reveal(canvas, real, ray, fraction * real.width, real.width, band=real.width * .22)
                plate_layer(canvas, cut, rect, plate, z, rot, center)
        else:
            points = plate_layer(canvas, real, rect, plate, z, rot, center)
        labels.append((name, points))
    # Labels with leader lines, one per kick.
    shown = count(t, KICKS[5:8]) + (2 if t >= KICKS[5] else 0)
    order = ['rail', 'calendar', 'sidebar', 'media', 'wallpaper']
    if explode > .6:
        draw = ImageDraw.Draw(canvas)
        for name, points in labels:
            if name not in order[:min(5, shown)]:
                continue
            anchor = points[1] if name != 'sidebar' else points[0]
            tx = min(W - 220, max(40, anchor[0] + (120 if name != 'sidebar' else -260)))
            ty = min(H - 200, max(70, anchor[1] - 40))
            color = LIME if t >= CLAPS[2] else WHITE
            draw.line([tuple(anchor), (tx, ty), (tx + 140, ty)], fill=color + (220,), width=2)
            put_text(canvas, name, 22, (tx + 4, ty - 18), color, mono=True, anchor='left', tracking=2)
    if t >= CLAPS[2]:
        put_text(canvas, 'every layer, designed.', 92, (960, 980), WHITE, scale=1 + .12 * pulse(t, CLAPS[2:3], .3))
    elif t < KICKS[3] + .15:
        put_text(canvas, 'look closer.', 92, (960, 980), WHITE, alpha=1 - since(t, KICKS[3], .15))
    zoom = 1 + .035 * pulse(t, KICKS[3:8] + CLAPS[1:3], .25)
    flash = max(pulse(t, CLAPS[1:3], .14), .6 * pulse(t, [KICKS[4]], .1), .3 * pulse(t, KICKS[5:8], .1))
    return finish(canvas, t, zoom, LIME if t >= CLAPS[2] else BLUE, .55 * flash)


def rail_scene(t):
    canvas = background()
    dot_field(canvas, t, alpha=18, drift=40)
    shot = count(t, [KICKS[8], CLAPS[3], KICKS[9]])
    # Three framings of the real rail, cut on the hits.
    focus = [(.08, 3.4), (.5, 3.0), (.88, 3.3), (.3, 2.2)][shot]
    wheel_index = (t - BARS[3]) / 1.4 * 39
    image = load(seq('wheel', wheel_index, 40))
    width = round(W * focus[1])
    strip = image.resize((width, round(image.height * width / image.width)), Image.Resampling.LANCZOS)
    pan = (t - last(t, [BARS[3], KICKS[8], CLAPS[3], KICKS[9]])) * 60
    x = round(W / 2 - focus[0] * width - pan)
    y = 420
    canvas.alpha_composite(strip, (x, y - strip.height // 2))
    # Reflection: the x-ray echo below.
    ray = xray(seq('wheel', wheel_index, 40), width, BLUE if shot < 2 else RED)
    canvas.alpha_composite(ray, (x, y + strip.height // 2 + 40))
    draw = ImageDraw.Draw(canvas)
    if t >= CLAPS[3]:
        grow = since(t, CLAPS[3], .2)
        draw.rectangle([0, 640, W * grow, 652], fill=RED + (255,))
    put_text(canvas, 'detailed down to', 64, (960, 760), WHITE, weight='Bold')
    put_text(canvas, 'the pixel.', 150, (960, 870), WHITE, scale=1 + .15 * pulse(t, [CLAPS[3]], .3))
    zoom = 1 + .04 * pulse(t, [KICKS[8], KICKS[9]], .25)
    return finish(canvas, t, zoom, RED, .5 * pulse(t, [CLAPS[3]], .12))


def calendar_scene(t):
    canvas = background()
    dot_field(canvas, t, alpha=18)
    local = t - BARS[4]
    frame = local / .9 * 45
    real = load(seq('calendar', frame, 46))
    shots = count(t, KICKS[10:13])
    yaw = [-14, 10, -6, 0][min(3, shots)]
    pitch = [10, -6, 8, 0][min(3, shots)]
    width = 1380 + 70 * pulse(t, KICKS[10:13], .3)
    image = real.resize((round(width), round(width * real.height / real.width)), Image.Resampling.LANCZOS)
    if t >= CLAPS[4]:
        sweep = (t - CLAPS[4]) / .55
        ray = xray(seq('calendar', 45, 46), image.width, RED)
        image = scan_reveal(canvas, image, ray, (1 - ease_io(sweep)) * (image.width + 400), image.width, band=image.width * 1.5)
    card(canvas, image, width, (960, 410), yaw=yaw * (1 - since(t, last(t, KICKS[10:13]) or 0, .5) * .5), pitch=pitch)
    put_text(canvas, 'live weather. system. time.', 44, (960, 860), WHITE, weight='Medium',
             alpha=since(t, KICKS[11], .15))
    put_text(canvas, 'useful at a glance.', 110, (960, 960), WHITE, scale=1 + .14 * pulse(t, [CLAPS[4]], .3),
             alpha=since(t, CLAPS[4], .08))
    zoom = 1 + .03 * pulse(t, KICKS[10:13], .25)
    return finish(canvas, t, zoom, RED, .5 * pulse(t, [CLAPS[4]], .12))


def media_sidebar(t):
    canvas = background()
    dot_field(canvas, t, alpha=18, drift=-30)
    media = scaled('media.png', 760)
    drop = since(t, KICKS[13], .32)
    y = -media.height * .45 + (media.height * .45 + 110) * drop
    shift = 200 * since(t, CLAPS[5], .3)
    card(canvas, media, 760, (960 + shift, y + media.height / 2), yaw=-10 * since(t, CLAPS[5], .3), pitch=4)
    if t >= CLAPS[5]:
        reveal = (t - CLAPS[5]) / .5
        index = min(29, reveal * 29)
        side = load(seq('sidebar', index, 30))
        card(canvas, side, 470, (560, 470), yaw=16, pitch=2)
    put_text(canvas, 'music. network. sound.', 44, (960, 905), WHITE, weight='Medium',
             alpha=since(t, KICKS[13], .15))
    put_text(canvas, 'built for every day.', 104, (960, 995), WHITE,
             scale=1 + .12 * pulse(t, [CLAPS[5], KICKS[14]], .3), alpha=since(t, CLAPS[5], .1))
    zoom = 1 + .035 * pulse(t, [KICKS[13], KICKS[14]], .25)
    return finish(canvas, t, zoom, BLUE, max(.5 * pulse(t, [CLAPS[5]], .12), .3 * pulse(t, [KICKS[13]], .1)))


SETTINGS = ['general', 'network', 'sound', 'battery', 'about']


def settings_scene(t):
    hits = [KICKS[15], KICKS[16], CLAPS[6], KICKS[17], BARS[7] - .3]
    index = max(0, count(t, hits) - 1)
    on_clap = index == 2
    canvas = background(LIME if on_clap and t - CLAPS[6] < .1 else BLACK)
    dot_field(canvas, t, alpha=18)
    name = f'settings-{SETTINGS[min(index, len(SETTINGS) - 1)]}.png'
    image = scaled(name, 1180)
    age = t - (last(t, hits) or BARS[6])
    slide = 1 - ease(age / .22)
    card(canvas, image, 1180, (960 + 180 * slide * (1 if index % 2 else -1), 470), yaw=-8 + 4 * index % 3, pitch=6,
         opacity=1)
    # Previous page as an x-ray ghost, leaving.
    if index > 0 and age < .3:
        previous = f'settings-{SETTINGS[index - 1]}.png'
        card(canvas, xray(previous, 1180, LIME), 1180, (960 - 300 * ease(age / .3) * (1 if index % 2 else -1), 470),
             yaw=-8, pitch=6, opacity=1 - age / .3)
    put_text(canvas, '14 pages of settings.', 104, (960, 960), WHITE, scale=1 + .1 * pulse(t, hits, .25))
    put_text(canvas, 'every option, one place.', 40, (960, 1040), WHITE, weight='Medium',
             alpha=since(t, CLAPS[6], .12))
    zoom = 1 + .03 * pulse(t, hits, .22)
    return finish(canvas, t, zoom, LIME, .45 * pulse(t, [CLAPS[6]], .12))


def motion_scene(t):
    canvas = background()
    dot_field(canvas, t, alpha=18, drift=50)
    local = t - BARS[7]
    # Onion-skinned reveal: the sidebar's real entrance frames as x-ray trails.
    cycle = (local % .83) / .83
    for echo in range(6, -1, -1):
        phase = max(0.0, cycle - echo * .05)
        index = phase * 29
        name = seq('sidebar', index, 30)
        x = 300 + 260 * ease(phase)
        if echo:
            card(canvas, xray(name, 360, BLUE if echo % 2 else WHITE), 360, (x, 540), yaw=18, opacity=.5 - echo * .06)
        else:
            card(canvas, load(name), 360, (x, 540), yaw=18)
    # Calendar subframes reveal on the right, restarted on each hit.
    hit = last(t, [BARS[7], KICKS[18], CLAPS[7], KICKS[19]]) or BARS[7]
    frame = (t - hit) / .5 * 45
    card(canvas, load(seq('calendar', frame, 46)), 820, (1300, 470), yaw=-16, pitch=4)
    put_text(canvas, 'motion that feels right.', 104, (1200, 900), WHITE,
             scale=1 + .12 * pulse(t, [CLAPS[7]], .3), alpha=since(t, KICKS[18], .12))
    put_text(canvas, 'smooth at 200 Hz.', 40, (1200, 990), WHITE, weight='Medium', alpha=since(t, CLAPS[7], .12))
    zoom = 1 + .035 * pulse(t, [KICKS[18], KICKS[19], CLAPS[7]], .25)
    return finish(canvas, t, zoom, BLUE, max(.5 * pulse(t, [CLAPS[7]], .12), .3 * pulse(t, [KICKS[18], KICKS[19]], .1)))


def login_scene(t):
    canvas = background()
    login = load(str(ROOT / 'config/sddm/ghost/preview.png'))
    local = t - BARS[8]
    scale = 1.55 - .45 * ease(local / 1.4)
    width = round(W * scale)
    image = login.resize((width, round(width * 1080 / 1920)), Image.Resampling.BILINEAR)
    x = round(W / 2 - width * .3)
    y = round(H / 2 - image.height * .55)
    canvas.alpha_composite(image, (x, y))
    # Password dots filling on the hits.
    dots = count(t, [KICKS[20], KICKS[21], CLAPS[8], KICKS[22]]) * 3
    draw = ImageDraw.Draw(canvas)
    fx = x + width * 0.1365
    fy = y + image.height * .676
    for i in range(min(12, dots)):
        r = 5 * scale
        draw.ellipse([fx + i * 16 * scale - r, fy - r, fx + i * 16 * scale + r, fy + r], fill=WHITE + (255,))
    if t >= CLAPS[8]:
        sweep = ease_io((t - CLAPS[8]) / .5)
        layer = canvas.crop((0, 0, W, H))
        ray = Image.new('RGBA', (W, H), BLACK + (255,))
        ray.alpha_composite(xray_frame(layer))
        canvas = scan_reveal(canvas, layer, ray, W * (1 - sweep) + 300, W, band=W * 1.2)
    put_text(canvas, 'from login', 120, (1420, 780), WHITE, scale=1 + .1 * pulse(t, [KICKS[20]], .3))
    put_text(canvas, 'to lock screen.', 120, (1420, 910), WHITE, alpha=since(t, CLAPS[8], .1),
             scale=1 + .12 * pulse(t, [CLAPS[8]], .3))
    zoom = 1 + .03 * pulse(t, [KICKS[20], KICKS[21], KICKS[22]], .25)
    return finish(canvas, t, zoom, RED, .5 * pulse(t, [CLAPS[8]], .12))


def open_scene(t):
    hits = [BARS[9], KICKS[23], CLAPS[9], KICKS[24]]
    step = max(0, count(t, hits) - 1)
    palette = [(BLACK, WHITE), (WHITE, BLACK), (LIME, BLACK), (BLUE, WHITE)][step]
    canvas = background(palette[0])
    words = ['created by', 'me.', 'and you.', 'open source.'][step]
    size = [120, 300, 300, 230][step]
    put_text(canvas, words, size, (960, 500), palette[1], scale=1 + .2 * pulse(t, hits, .3))
    if step >= 1:
        put_text(canvas, 'ghOSt is built in the open. bring your ideas.', 38, (960, 760), palette[1],
                 weight='Medium', alpha=.9)
    zoom = 1 + .05 * pulse(t, hits, .25)
    return finish(canvas, t, zoom, WHITE, .35 * pulse(t, hits[1:], .1), int(10 * pulse(t, hits[1:], .15)))


def finale(t):
    canvas = background()
    dot_field(canvas, t, alpha=20)
    local = t - BARS[10]
    mark_size = round(300 + 40 * pulse(t, [KICKS[25], KICKS[26]], .3))
    mark = scaled(GHOST, mark_size)
    canvas.alpha_composite(mark, (960 - mark.width // 2, 380 - mark.height // 2))
    put_text(canvas, 'ghOSt', 200, (960, 660), WHITE, scale=1 + .1 * pulse(t, [KICKS[26]], .3))
    if t >= CLAPS[10]:
        put_text(canvas, 'github.com/dsksnkz/ghOSt', 40, (960, 820), WHITE, mono=True,
                 scale=1 + .25 * pulse(t, [CLAPS[10]], .3))
    if local < .5:
        ray = xray(OUTLINE, 900, WHITE)
        card(canvas, ray, 900 + 600 * ease(local / .5), (960, 420), opacity=1 - local / .5)
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
