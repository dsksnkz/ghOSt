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


PURE = (255, 255, 255)
_OVERLAY = [None]


def overlay():
    """Clean top layer: text, cursor and callout lines, drawn after grain and colour."""
    if _OVERLAY[0] is None:
        _OVERLAY[0] = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    return _OVERLAY[0]


def put_text(canvas, value, size, center, color=WHITE, weight='Black', scale=1.0, alpha=1.0,
             mono=False, tracking=0, anchor='center', layer='overlay'):
    # Labels stay plain: pure white (or pure black on light fields), never scaled.
    color = PURE if color in (WHITE, (140, 140, 138)) else color
    image = text_image(value, size, color, weight, mono, tracking)
    if alpha < 1:
        image = image.copy()
        image.putalpha(image.getchannel('A').point(lambda v: round(v * max(0, alpha))))
    x, y = center
    if anchor == 'center':
        position = (round(x - image.width / 2), round(y - image.height / 2))
    else:
        position = (round(x), round(y - image.height / 2))
    (overlay() if layer == 'overlay' else canvas).alpha_composite(image, position)
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


def finish(canvas, t, zoom=1.0, flash=None, flash_amount=0.0, split=0, hard=False):
    # No per-beat camera punches or colour splits: only deliberate fades (hard=True).
    array = np.asarray(canvas.convert('RGB')).astype(np.float32)
    array += grain(int(t * FPS) % 4) * .7
    top = np.asarray(overlay()).astype(np.float32)
    alpha = top[..., 3:4] / 255
    array = array * (1 - alpha) + top[..., :3] * alpha
    if hard and flash and flash_amount > 0.002:
        array = array * (1 - flash_amount) + np.array(flash, np.float32) * flash_amount
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
MEDIA_SEEK = ((20, 156), (372, 156))
SIDE_SLIDER = ((45, 437), (405, 437))
SETTINGS_NAV = {'wireless': 75, 'bluetooth': 97, 'general': 119, 'sound': 190, 'battery': 212, 'brightness': 235}


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


def hud(canvas, t, section):
    """Thin frame, section name and timecode on the clean layer."""
    draw = ImageDraw.Draw(overlay())
    draw.rectangle([36, 36, W - 36, H - 36], outline=PURE + (40,), width=1)
    put_text(canvas, 'ghOSt / ' + section, 18, (56, 62), PURE, mono=True, anchor='left')
    put_text(canvas, f'{int(t // 60):02d}:{t % 60:05.2f}', 18, (W - 160, 62), PURE, mono=True, anchor='left')
    draw.rectangle([36, H - 38, 36 + (W - 72) * t / DURATION, H - 36], fill=PURE + (150,))


def label(t, start, position, text, size=26, end=None, anchor='left'):
    """A plain white label that fades in (and optionally out); no other effects."""
    if t < start or (end is not None and t > end + .15):
        return
    alpha = since(t, start, .05) * (1 - (since(t, end, .12) if end is not None else 0))
    put_text(None, text, size, position, PURE, weight='Medium', alpha=alpha, anchor=anchor)


def callout(canvas, t, start, anchor, text, sub='', dx=120, dy=-60, color=WHITE):
    """A dot on a real feature, a leader line drawn in, then its label."""
    if t < start:
        return
    grow = ease((t - start) / .25)
    draw = ImageDraw.Draw(overlay())
    ax, ay = anchor
    ex, ey = ax + dx * min(1, grow * 1.6), ay + dy * min(1, grow * 1.6)
    draw.ellipse([ax - 6, ay - 6, ax + 6, ay + 6], fill=PURE + (255,))
    age = t - start
    if age < .4:
        r = 10 + 34 * ease(age / .4)
        draw.ellipse([ax - r, ay - r, ax + r, ay + r], outline=PURE + (round(240 * (1 - age / .4)),), width=3)
    draw.line([(ax, ay), (ex, ey)], fill=PURE + (230,), width=2)
    if grow > .55:
        direction = 1 if dx >= 0 else -1
        tx = ex + direction * 30 * ease((grow - .55) / .45)
        draw.line([(ex, ey), (tx, ey)], fill=PURE + (230,), width=2)
        alpha = ease((grow - .6) / .4)
        title = text_image(text, 28, PURE, 'Bold')
        note = text_image(sub, 20, PURE, 'Medium') if sub else None
        span = max(title.width, note.width if note else 0)
        lx = tx + 12 if direction > 0 else tx - 12 - span
        lx = min(W - 60 - span, max(60, lx))
        put_text(canvas, text, 28, (lx, ey - 6), PURE, weight='Bold', anchor='left', alpha=alpha)
        if sub:
            put_text(canvas, sub, 20, (lx + 1, ey + 24), PURE, weight='Medium', anchor='left', alpha=alpha)


# ── cursor ──────────────────────────────────────────────────────────────────
ARROW = [(0, 0), (0, 25), (6.5, 19.5), (11, 29.5), (15.5, 27.5), (11, 18), (19, 18)]


def path_point(t, keys):
    """Eased position along (time, (x, y)) keyframes."""
    if t <= keys[0][0]:
        return keys[0][1]
    for (t0, p0), (t1, p1) in zip(keys, keys[1:]):
        if t <= t1:
            f = ease_io((t - t0) / max(1e-6, t1 - t0))
            return (p0[0] + (p1[0] - p0[0]) * f, p0[1] + (p1[1] - p0[1]) * f)
    return keys[-1][1]


def draw_cursor(position, t, clicks, scale=1.0):
    draw = ImageDraw.Draw(overlay())
    x, y = position
    for click in clicks:
        age = t - click
        if 0 <= age < .45:
            r = (8 + 34 * ease(age / .45)) * scale
            draw.ellipse([x - r, y - r, x + r, y + r], outline=PURE + (round(230 * (1 - age / .45)),), width=2)
    pressed = any(0 <= t - click < .1 for click in clicks)
    k = scale * (.88 if pressed else 1)
    points = [(x + px * k, y + py * k) for px, py in ARROW]
    draw.polygon(points, fill=PURE + (255,), outline=(0, 0, 0, 255))
    draw.line(points + [points[0]], fill=(0, 0, 0, 255), width=max(1, round(1.6 * scale)))


# ── desktop walkthrough: one stage, one smooth camera ───────────────────────
WALK = (BARS[3], BARS[6])
CLICK_CLOCK = CLAPS[3]
CLICK_MUSIC = KICKS[13]
CLICK_MENU = CLAPS[5]
PAD = 170  # headroom above the rail so the camera can frame it mid-screen
CAL_POS = ((1920 - 918) // 2, 82 + PAD)
MEDIA_POS = (214, 68 + PAD)
SIDE_POS = (16, 82 + PAD)


def walk_cursor_keys():
    k = KICKS
    seek = lambda f: (214 + 20 + f * 352, 68 + 156)
    keys = [
        (BARS[3], (600, 300)), (k[8] - .12, (172, 27)), (k[8] + .35, (176, 30)),
        (CLICK_CLOCK - .16, (960, 27)), (k[9] - .1, (960, 27)), (k[9] + .1, (590, 360)),
        (k[10] - .08, (600, 330)), (k[11], (600, 345)), (k[12], (600, 360)), (CLAPS[4], (980, 300)),
        (CLICK_MUSIC - .18, (410, 27)), (CLICK_MUSIC + .04, (410, 27)),
        (CLICK_MUSIC + .2, seek(.36)), (CLICK_MENU - .14, seek(.72)),
        (CLICK_MENU - .02, (45, 27)), (CLICK_MENU + .2, (45, 27)),
        (k[14] - .12, (16 + 45 + 240, 82 + 437)), (k[14], (16 + 45 + 240, 82 + 437)),
        (BARS[6], (16 + 45 + 330, 82 + 437)),
    ]
    return [(time, (x, y + PAD)) for time, (x, y) in keys]


CAMERA = [
    (BARS[3], (430, 40, 2.4)), (KICKS[8] + .3, (520, 40, 2.2)), (CLICK_CLOCK, (960, 90, 1.9)),
    (CLICK_CLOCK + .45, (960, 270, 1.55)), (BARS[5] - .05, (960, 270, 1.55)),
    (CLICK_MUSIC + .2, (520, 200, 1.75)), (CLICK_MENU, (480, 280, 1.6)), (BARS[6], (420, 420, 1.55)),
]
CAMERA = [(time, (x, y + PAD, zoom)) for time, (x, y, zoom) in CAMERA]


def camera(t):
    if t <= CAMERA[0][0]:
        return CAMERA[0][1]
    for (t0, a), (t1, b) in zip(CAMERA, CAMERA[1:]):
        if t <= t1:
            f = ease_io((t - t0) / max(1e-6, t1 - t0))
            return tuple(a[i] + (b[i] - a[i]) * f for i in range(3))
    return CAMERA[-1][1]


def stage(t):
    # Plain dark field: the wallpaper's wordmark would compete with the headlines.
    plate = Image.new('RGBA', (1920, 1080 + PAD), (17, 17, 18, 255))
    # Workspace wheel turns while the cursor scrolls over it.
    wheel = 39 * ease_io((t - KICKS[8]) / .7)
    rail = load(seq('wheel', wheel, 40)).resize((1920, 50), Image.Resampling.LANCZOS)
    # Calendar: opened by the clock click, forecast scrolled on the kicks.
    if CLICK_CLOCK <= t < BARS[5] + .25:
        if t < BARS[4]:
            # Groups appear at 280..1280 ms of reveal; map 1280 ms onto the next kick.
            elapsed = (t - CLICK_CLOCK) * 1280 / (KICKS[9] - CLICK_CLOCK)
            frame = load(seq('calendar', min(1500, elapsed) / 1500 * 45, 46))
        else:
            step = count(t, KICKS[10:13])
            frame = load(seq('forecast', [2, 3, 4, 1][step], 5))
            if t >= CLAPS[4]:
                ray = xray(seq('forecast', [2, 3, 4, 1][step], 5), frame.width, RED)
                frame = scan_reveal(None, frame, ray, (1 - ease((t - CLAPS[4]) / .55)) * frame.width,
                                    frame.width, band=frame.width * 1.5)
        cal = frame.resize((918, 425), Image.Resampling.LANCZOS)
        close = since(t, BARS[5] + .02, .2)
        if close > 0:
            cal.putalpha(cal.getchannel('A').point(lambda v: round(v * (1 - close))))
        reveal = since(t, CLICK_CLOCK, .26)
        plate.alpha_composite(cal, (CAL_POS[0], round(CAL_POS[1] - 30 * (1 - reveal) - 20 * close)))
    # Media popup: slides down from behind the rail; the seek bar is dragged.
    if CLICK_MUSIC <= t < CLICK_MENU + .2:
        media = scaled('media.png', 392).copy()
        drag = ease_io((t - (CLICK_MUSIC + .2)) / max(.1, CLICK_MENU - .14 - CLICK_MUSIC - .2))
        progress = .36 + .36 * drag
        draw = ImageDraw.Draw(media)
        (x0, y0), (x1, _) = MEDIA_SEEK
        draw.rounded_rectangle([x0, y0 - 2, x0 + (x1 - x0) * progress, y0 + 2], 2, fill=WHITE + (255,))
        kx = x0 + (x1 - x0) * progress
        draw.ellipse([kx - 6, y0 - 6, kx + 6, y0 + 6], fill=WHITE + (255,))
        slide = .35 + .65 * since(t, CLICK_MUSIC, .24)
        out = since(t, CLICK_MENU, .2)
        y = round(MEDIA_POS[1] - (262 + 68) * (1 - slide) - (262 + 68) * out)
        clip = Image.new('RGBA', (392, 262), (0, 0, 0, 0))
        clip.alpha_composite(media, (0, 0))
        # Emerges from behind the rail, never above it.
        visible_top = PAD + 50
        if y < visible_top:
            cut = visible_top - y
            if cut < 262:
                plate.alpha_composite(clip.crop((0, cut, 392, 262)), (MEDIA_POS[0], visible_top))
        else:
            plate.alpha_composite(clip, (MEDIA_POS[0], y))
    # Sidebar: opened from the menu button; the volume slider is dragged.
    if t >= CLICK_MENU:
        side = load(seq('sidebar', 5 + (t - CLICK_MENU) / .4 * 24, 30)).resize((410, 914), Image.Resampling.LANCZOS)
        if t >= KICKS[14]:
            drag = ease((t - KICKS[14]) / .45)
            draw = ImageDraw.Draw(side)
            (x0, y0), (x1, _) = SIDE_SLIDER
            fill = .62 + .25 * drag
            draw.rounded_rectangle([x0 - 25, y0 - 16, x0 - 25 + (x1 - x0 + 25) * fill, y0 + 16], 9,
                                   fill=(226, 226, 224, 255))
        plate.alpha_composite(side, SIDE_POS)
    plate.alpha_composite(rail, (0, PAD))
    return plate


def desk_walk(t):
    cx, cy, zoom = camera(t)
    plate = stage(t)
    cw, ch = W / zoom, H / zoom
    left = min(1920 - cw, max(0, cx - cw / 2))
    top = min(plate.height - ch, max(0, cy - ch / 2))
    view = plate.resize((W, H), Image.Resampling.BICUBIC, box=(left, top, left + cw, top + ch))
    canvas = view.convert('RGBA')
    # Legibility band for the headline: a plain dark gradient, not a text effect.
    shade = Image.new('L', (1, 300))
    shade.putdata([round(230 * (i / 299) ** 1.4) for i in range(300)])
    band = Image.new('RGBA', (W, 300), BLACK + (0,))
    band.putalpha(shade.resize((W, 300)))
    canvas.alpha_composite(band, (0, H - 300))
    to_screen = lambda x, y: ((x - left) * zoom, (y - top) * zoom)
    pos = to_screen(*path_point(t, walk_cursor_keys()))
    clicks = [CLICK_CLOCK, CLICK_MUSIC, CLICK_MENU, KICKS[14]]
    draw_cursor(pos, t, clicks, scale=1.3)
    # Scroll hint: two chevrons beside the cursor while it scrolls.
    for start, length in ((KICKS[8], .6), (KICKS[10] - .05, 1.3)):
        if start <= t < start + length:
            draw = ImageDraw.Draw(overlay())
            phase = (t - start) * 6 % 1
            for i in range(2):
                yy = pos[1] + 44 + i * 12 + phase * 6
                draw.line([(pos[0] + 34, yy), (pos[0] + 42, yy + 7), (pos[0] + 50, yy)], fill=PURE + (220,), width=3)
    # Plain labels near the action.
    label(t, KICKS[8], (pos[0] + 70, pos[1] + 64), 'scroll to switch desktops', end=CLICK_CLOCK - .2)
    label(t, CLICK_CLOCK, (pos[0] + 70, pos[1] + 64), 'click the clock', end=KICKS[9] + .05)
    label(t, KICKS[10], (pos[0] + 70, pos[1] - 10), 'scroll the forecast', end=CLAPS[4])
    label(t, CLICK_MUSIC, (pos[0] + 70, pos[1] + 64), 'open what is playing', end=CLICK_MUSIC + .3)
    label(t, CLICK_MUSIC + .35, (pos[0] + 40, pos[1] + 84), 'drag to seek', end=CLICK_MENU - .1)
    label(t, CLICK_MENU, (pos[0] + 70, pos[1] + 64), 'menu opens the sidebar', end=KICKS[14] - .15)
    label(t, KICKS[14] - .1, (pos[0] + 70, pos[1] + 64), 'drag for volume')
    heading = 'detailed down to the pixel.' if t < BARS[4] else 'useful at a glance.' if t < BARS[5] else 'built for every day.'
    hit = BARS[3] if t < BARS[4] else BARS[4] if t < BARS[5] else BARS[5]
    put_text(canvas, heading, 96, (960, 975), PURE, alpha=since(t, hit, .05))
    hud(canvas, t, 'rail' if t < BARS[4] else 'calendar' if t < BARS[5] else 'media + sidebar')
    return finish(canvas, t)


# ── scenes ──────────────────────────────────────────────────────────────────
def intro(t):
    canvas = background()
    ray = desktop_xray((90, 90, 92)).copy()
    ray.putalpha(ray.getchannel('A').point(lambda v: round(v * .55)))
    canvas.alpha_composite(ray)
    scan = 1920 * ease_io(t / 1.9)
    draw = ImageDraw.Draw(canvas)
    draw.rectangle([scan - 2, 0, scan + 2, H], fill=BLUE + (170,))
    draw.rectangle([0, 470, W, 610], fill=BLACK + (235,))
    line = 'every rice looks the same.'
    shown = line[:int(len(line) * ease_io((t - .15) / .9))]
    if shown:
        put_text(canvas, shown, 54, (960, 540), PURE, mono=True, alpha=1 - since(t, 1.25, .25))
    if t > 1.15:
        grow = ease((t - 1.15) / .8)
        card(canvas, xray(OUTLINE, 520, WHITE), 360 + 260 * grow, (960, 540), roll=-8 * (1 - grow), opacity=grow)
    whiteout = max(0.0, (t - 1.70) / .26)
    return finish(canvas, t, flash=WHITE, flash_amount=min(1, whiteout) * .45, hard=True)


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
    fg = PURE if (inverted or blue) else (0, 0, 0)
    canvas = background(bg)
    ray = desktop_xray(WHITE if fg == PURE else BLACK)
    layer = ray.resize((round(W * 1.25), round(H * 1.25)), Image.Resampling.BILINEAR)
    layer.putalpha(layer.getchannel('A').point(lambda v: round(v * .2)))
    canvas.alpha_composite(layer, (round(-200 - (t - BARS[0]) * 60), -130))
    mark = scaled(GHOST, 260) if fg == PURE else _dark_mark()
    words = 'is here.' if t >= KICKS[2] else 'ghOSt'
    put_text(canvas, words, 300, (1040, 520), fg)
    if t < KICKS[2]:
        canvas.alpha_composite(mark, (160, 520 - mark.height // 2 - 10))
    if t >= CLAPS[0]:
        put_text(canvas, 'a desktop shell for Hyprland', 44, (1040, 760), fg, weight='Medium',
                 alpha=since(t, CLAPS[0], .05))
        put_text(canvas, 'built in QML on Quickshell', 24, (1040, 830), fg, weight='Medium',
                 alpha=since(t, CLAPS[0], .05))
    return finish(canvas, t)


LAYERS = [
    ('wallpaper', (0, 0, 1920, 1080), 'your image, untouched'),
    ('sidebar', (16, 82, 410, 914), 'network, bluetooth, sound'),
    ('calendar', ((1920 - 918) // 2, 82, 918, 425), 'weather, system, month'),
    ('media', (1450, 68, 392, 262), 'now playing'),
    ('rail', (0, 0, 1920, 50), 'workspaces, music, clock'),
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
    tilt = since(t, KICKS[3], .45)
    explode = since(t, KICKS[4], .55)
    ray_on = t >= CLAPS[1]
    accent = BLUE if t < CLAPS[2] else LIME
    yaw = -24 * tilt + 5 * since(t, KICKS[6], .6) - 5 * since(t, KICKS[7], .6)
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
                    dy=-70 if name != 'wallpaper' else 60)
    if t >= CLAPS[2]:
        put_text(canvas, 'every layer, designed.', 92, (960, 975), PURE, alpha=since(t, CLAPS[2], .05))
    elif t < KICKS[3] + .15:
        put_text(canvas, 'look closer.', 92, (960, 975), PURE, alpha=1 - since(t, KICKS[3], .15))
    hud(canvas, t, 'layers')
    return finish(canvas, t)


SETTINGS = ['general', 'bluetooth', 'sound', 'battery', 'brightness']


def settings_scene(t):
    hits = [KICKS[15], KICKS[16], CLAPS[6], KICKS[17], BARS[7] - .3]
    index = max(0, count(t, hits) - 1)
    canvas = background()
    backdrop(canvas, t, 'rail', dim=.86)
    name = SETTINGS[min(index, len(SETTINGS) - 1)]
    width = 1260
    page = scaled(f'settings-{name}.png', width)
    left, top = (W - width) // 2, 110
    # Outgoing page crossfades out over a short slide: one clean motion per click.
    age = t - (last(t, hits) or BARS[6])
    canvas.alpha_composite(page, (left, top))
    k = width / 1024
    keys = [(BARS[6], (left + 70 * k, top + SETTINGS_NAV['general'] * k))]
    for hit, target in zip(hits[1:], SETTINGS[1:]):
        keys.append((hit - .16, (left + 70 * k, top + SETTINGS_NAV[target] * k)))
        keys.append((hit, (left + 70 * k, top + SETTINGS_NAV[target] * k)))
    position = path_point(t, keys)
    draw_cursor(position, t, hits[1:], scale=1.2)
    label(t, KICKS[15], (left + 260 * k, top + 40 * k), name.capitalize(), size=30)
    put_text(canvas, '14 pages of settings.', 96, (960, 1000), PURE, alpha=since(t, KICKS[15], .05))
    hud(canvas, t, 'settings')
    return finish(canvas, t)


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
    draw = ImageDraw.Draw(overlay())
    x0, y0, gw, gh = 760, 760, 1060, 70
    draw.line([(x0, y0 + gh), (x0 + gw, y0 + gh)], fill=PURE + (60,), width=1)
    jitter = np.random.default_rng(3).normal(0, .18, 400)
    points = [(x0 + i * gw / 159, y0 + gh - ((5.1 + jitter[(i + int(local * 120)) % 400]) / 10) * gh)
              for i in range(160)]
    draw.line(points, fill=PURE + (255,), width=2)
    put_text(canvas, '5.1 ms per frame', 22, (x0, y0 - 18), PURE, weight='Medium', anchor='left')
    put_text(canvas, 'motion that feels right.', 92, (1240, 900), PURE, alpha=since(t, KICKS[18], .05))
    put_text(canvas, 'smooth at 200 Hz.', 36, (1240, 985), PURE, weight='Medium', alpha=since(t, CLAPS[7], .05))
    hud(canvas, t, 'motion')
    return finish(canvas, t)


SDDM_POINTS = {'password': (450, 731), 'keyboard': (259, 1011), 'session': (330, 1011), 'power': (1837, 1011)}


def login_scene(t):
    canvas = background()
    login = load(str(ROOT / 'config/sddm/ghost/preview.png'))
    local = t - BARS[8]
    scale = 1.25 - .25 * ease_io(local / 1.6)
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
        sweep = ease((t - CLAPS[8]) / .5)
        layer = canvas.crop((0, 0, W, H))
        ray = Image.new('RGBA', (W, H), BLACK + (255,))
        ray.alpha_composite(xray_frame(layer))
        canvas = scan_reveal(canvas, layer, ray, W * (1 - sweep), W, band=W * 1.2)
    put_text(canvas, 'from login', 110, (1420, 380), PURE, alpha=since(t, KICKS[20], .05))
    put_text(canvas, 'to lock screen.', 110, (1420, 500), PURE, alpha=since(t, CLAPS[8], .05))
    put_text(canvas, 'its own SDDM theme, same design', 26, (1420, 590), PURE, weight='Medium',
             alpha=since(t, CLAPS[8], .05))
    hud(canvas, t, 'login')
    return finish(canvas, t)


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
                 anchor='left', alpha=alpha / 255, layer='canvas')


def open_scene(t):
    hits = [BARS[9], KICKS[23], CLAPS[9], KICKS[24]]
    step = max(0, count(t, hits) - 1)
    palette = [(BLACK, PURE), (WHITE, (0, 0, 0)), (LIME, (0, 0, 0)), (BLUE, PURE)][step]
    canvas = background(palette[0])
    commit_wall(canvas, t, palette[1], alpha=46)
    words = ['created by', 'me.', 'and you.', 'open source.'][step]
    size = [120, 300, 300, 230][step]
    plate = Image.new('RGBA', (W, 380), palette[0] + (225,))
    canvas.alpha_composite(plate, (0, 310))
    put_text(canvas, words, size, (960, 500), palette[1])
    if step >= 1:
        put_text(canvas, 'every commit is public. bring your ideas.', 38, (960, 760), palette[1], weight='Medium')
    return finish(canvas, t)


def finale(t):
    canvas = background()
    ray = desktop_xray((70, 70, 72)).copy()
    ray.putalpha(ray.getchannel('A').point(lambda v: round(v * .5)))
    canvas.alpha_composite(ray)
    local = t - BARS[10]
    mark = scaled(GHOST, 300)
    rise = since(t, BARS[10], .4)
    canvas.alpha_composite(mark, (960 - mark.width // 2, round(360 - mark.height // 2 + 30 * (1 - rise))))
    put_text(canvas, 'ghOSt', 200, (960, 640), PURE, alpha=rise)
    put_text(canvas, 'rail, calendar, sidebar, media, settings, lock, login', 26, (960, 770), PURE,
             weight='Medium', alpha=since(t, KICKS[26], .05))
    if t >= CLAPS[10]:
        put_text(canvas, 'github.com/dsksnkz/ghOSt', 40, (960, 850), PURE, mono=True, alpha=since(t, CLAPS[10], .05))
    if local < .5:
        card(canvas, xray(OUTLINE, 900, WHITE), 900 + 600 * ease(local / .5), (960, 420), opacity=1 - local / .5)
    fade = max(0.0, (t - 19.55) / .45)
    return finish(canvas, t, flash=BLACK, flash_amount=min(1, fade), hard=True)


SCENES = [(0, intro), (BARS[0], identity), (BARS[1], xray_stack), (BARS[3], desk_walk),
          (BARS[6], settings_scene), (BARS[7], motion_scene), (BARS[8], login_scene), (BARS[9], open_scene),
          (BARS[10], finale)]


def render_frame(index):
    t = min(DURATION - .5 / FPS, index / FPS * SPEED)
    scene = [function for start, function in SCENES if t >= start - 1e-6][-1]
    _OVERLAY[0] = None
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
