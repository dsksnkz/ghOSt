#!/usr/bin/env python3
"""A reproducible monochrome product film using captured ghOSt QML frames."""
from functools import lru_cache
import math
from pathlib import Path
import subprocess
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / '.local/ad-production-hq'
OUTPUT = ASSETS / 'ghOSt-advertisement.mp4'
WIDTH, HEIGHT, FPS, DURATION = 1920, 1080, 30, 26
FONTS = ROOT / 'config/quickshell/ghost-bar/fonts'


def ease(value):
    value = max(0, min(1, value))
    return 1 - (1 - value) ** 3


def mix(first, second, fraction):
    return first + (second - first) * fraction


@lru_cache(maxsize=20)
def font(size, brand=False):
    name = 'TurretRoad-Medium.ttf' if brand else 'JetBrainsMono-Regular.ttf'
    return ImageFont.truetype(str(FONTS / name), size)


@lru_cache(maxsize=180)
def texture(path):
    with Image.open(path) as source:
        return source.convert('RGBA')


def sequence(name, moment, count, crop=None):
    index = min(count - 1, max(0, int(moment * FPS)))
    image = texture(str(ASSETS / name / f'{index:04d}.png'))
    return image.crop(crop) if crop else image


def rotation(yaw, pitch, roll):
    y, p, r = np.radians([yaw, pitch, roll])
    cy, sy, cp, sp, cr, sr = math.cos(y), math.sin(y), math.cos(p), math.sin(p), math.cos(r), math.sin(r)
    return np.array([[cr, -sr, 0], [sr, cr, 0], [0, 0, 1]]) @ np.array([
        [1, 0, 0], [0, cp, -sp], [0, sp, cp]]) @ np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])


def project(points, center=(960, 540), focal=1700):
    points = np.asarray(points)
    factor = focal / (focal + points[:, 2])
    return np.stack((center[0] + points[:, 0] * factor,
                     center[1] + points[:, 1] * factor), axis=1)


def plane_points(width, height, center, yaw=0, pitch=0, roll=0):
    corners = np.array([[-width / 2, -height / 2, 0], [width / 2, -height / 2, 0],
                        [width / 2, height / 2, 0], [-width / 2, height / 2, 0]])
    return project(corners @ rotation(yaw, pitch, roll).T, center)


def perspective_coefficients(destination, source):
    equations, values = [], []
    for (x, y), (u, v) in zip(destination, source):
        equations.extend([[x, y, 1, 0, 0, 0, -u * x, -u * y],
                          [0, 0, 0, x, y, 1, -v * x, -v * y]])
        values.extend([u, v])
    return np.linalg.solve(np.asarray(equations), np.asarray(values))


def card(canvas, image, width, center, yaw=0, pitch=0, roll=0, opacity=1, outline=False):
    height = width * image.height / image.width
    corners = plane_points(width, height, center, yaw, pitch, roll)
    left, top = np.floor(corners.min(axis=0)).astype(int)
    right, bottom = np.ceil(corners.max(axis=0)).astype(int)
    if right <= left or bottom <= top:
        return corners
    local = corners - [left, top]
    coefficients = perspective_coefficients(local, [(0, 0), (image.width, 0),
                                                     (image.width, image.height), (0, image.height)])
    warped = image.transform((right - left, bottom - top), Image.Transform.PERSPECTIVE,
                             coefficients, Image.Resampling.BICUBIC)
    if opacity < 1:
        warped.putalpha(warped.getchannel('A').point(lambda value: round(value * max(0, opacity))))
    canvas.alpha_composite(warped, (int(left), int(top)))
    if outline:
        ImageDraw.Draw(canvas).line([tuple(point) for point in corners] + [tuple(corners[0])],
                                   fill=(180, 180, 180, 150), width=1)
    return corners


def make_background(light):
    y, x = np.mgrid[0:HEIGHT, 0:WIDTH]
    radius = ((x - WIDTH * .57) / WIDTH) ** 2 + ((y - HEIGHT * .4) / HEIGHT) ** 2
    grain = np.random.default_rng(17).normal(0, .42, (HEIGHT, WIDTH))
    tone = (235 - radius * 24 if light else 9 + 9 * np.exp(-radius * 8)) + grain
    rgb = np.repeat(np.clip(tone, 0, 255).astype('uint8')[..., None], 3, axis=2)
    return Image.fromarray(rgb).convert('RGBA')


BACKGROUNDS = {False: make_background(False), True: make_background(True)}


def technical_field(canvas, moment, light=False, strength=1):
    draw = ImageDraw.Draw(canvas)
    ink = round(mix(30, 192, 0 if light else 1))
    faint = (ink, ink, ink, round(48 * strength))
    matrix = rotation(8 * math.sin(moment * .28), 66, -8 + moment * .3)
    for offset in range(-1000, 1001, 100):
        for axis in (0, 1):
            line = np.array([[offset, -1000, 200], [offset, 1000, 200]])
            if axis:
                line[:, :2] = line[:, :2][:, ::-1]
            points = project(line @ matrix.T, (1120, 760), 1600)
            draw.line([tuple(point) for point in points], fill=faint, width=1)
    # Offset elliptical trajectories, matching the reference's orbital drafting.
    for ring in range(3):
        theta = np.linspace(0, math.tau, 110)
        radius = 350 + ring * 110
        orbit = np.stack((radius * np.cos(theta), radius * np.sin(theta),
                          45 * np.sin(theta * 3 + moment)), axis=1)
        orbit = orbit @ rotation(moment * 6 + ring * 31, 45 + ring * 9, ring * 30).T
        points = project(orbit, (1080, 530))
        draw.line([tuple(point) for point in points], fill=faint, width=1)
        dot = points[(int(moment * 12) + ring * 27) % len(points)]
        draw.ellipse((dot[0] - 3, dot[1] - 3, dot[0] + 3, dot[1] + 3),
                     fill=(ink, ink, ink, 180))


def text(canvas, position, value, size=22, light=False, alpha=255, brand=False):
    tone = 24 if light else 240
    ImageDraw.Draw(canvas).text(position, value, font=font(size, brand),
                               fill=(tone, tone, tone, round(alpha)))


def caption(canvas, number, title, light=False):
    text(canvas, (84, 76), f'{number:02d} / {title}', 22, light)
    text(canvas, (84, 1030), 'ghOSt', 21, light, brand=True)
    draw = ImageDraw.Draw(canvas)
    tone = 80 if light else 118
    draw.line((84, 117, 340, 117), fill=(tone, tone, tone, 200), width=1)


def pointer(canvas, position, pressed=False):
    x, y = position
    draw = ImageDraw.Draw(canvas)
    draw.polygon([(x, y), (x + 4, y + 29), (x + 11, y + 21),
                  (x + 21, y + 20)], fill='#f4f4f4', outline='#151515')
    if pressed:
        draw.ellipse((x - 17, y - 17, x + 17, y + 17), outline='#c4c4c4', width=1)


def logo_texture():
    image = Image.new('RGBA', (1050, 270))
    ImageDraw.Draw(image).text((35, 0), 'ghOSt', font=font(230, True), fill='#171717')
    return image


LOGO = logo_texture()


def intro(canvas, moment):
    technical_field(canvas, moment, True, .7)
    draw = ImageDraw.Draw(canvas)
    # Architectural folded planes: counter-rotation and depth, not flash spam.
    for index in range(5):
        points = plane_points(280 + index * 65, 400, (1350 + index * 32, 550),
                              -58 + moment * 22 + index * 8, 13, -18)
        shade = 190 + index * 8
        draw.polygon([tuple(point) for point in points], fill=(shade, shade, shade, 80))
        draw.line([tuple(point) for point in points] + [tuple(points[0])], fill='#d7d7d7', width=1)
    card(canvas, LOGO, 760, (590, 460), -12 * (1 - ease(moment / .8)),
         roll=-3 * (1 - ease(moment / .8)), opacity=ease(moment / .45))
    text(canvas, (170, 640), 'GRAPHICAL HYPRLAND', 20, True, ease((moment - .35) / .5) * 255)
    text(canvas, (170, 672), 'OPERATING SYSTEM TOOLKIT', 20, True, ease((moment - .55) / .5) * 255)
    draw.line((170, 730, 660, 730), fill='#a7a7a7', width=1)


def desktops(canvas, moment):
    technical_field(canvas, moment + 2)
    caption(canvas, 1, 'DESKTOPS')
    rail = sequence('wheel', moment, 90)
    card(canvas, rail, 1680, (960, 260), pitch=8 * math.sin(moment), opacity=ease(moment / .25))
    crop = rail.crop((210, 0, 505, 100))
    card(canvas, crop, 890, (970, 565), yaw=10 * math.sin(moment), pitch=-7,
         roll=-2, opacity=ease(moment / .3), outline=True)
    text(canvas, (720, 815), '01  /  02  /  03  /  04  /  05', 22)
    pointer(canvas, (960, 670), (moment % .9) < .18)


def volume(canvas, moment):
    technical_field(canvas, moment + 5)
    caption(canvas, 2, 'VOLUME / SCROLL')
    rail = sequence('volume', moment, 66)
    card(canvas, rail, 1720, (960, 310), pitch=-3, opacity=ease(moment / .2))
    detail = rail.crop((3010, 0, 3300, 100))
    card(canvas, detail, 820, (1040, 620), yaw=-8 + 8 * ease(moment / 1.5),
         roll=2, opacity=ease(moment / .3), outline=True)
    pointer(canvas, (920, 590), (moment % .25) < .09)
    draw = ImageDraw.Draw(canvas)
    for index in range(5):
        y = 795 + index * 12 - (moment * 50 % 12)
        draw.line((915, y, 925, y), fill='#8a8a8a', width=2)


def calendar_scene(canvas, moment):
    technical_field(canvas, moment + 7, strength=.5)
    caption(canvas, 3, 'CALENDAR / TELEMETRY')
    image = sequence('calendar-framed', moment, 150)
    reveal = ease(moment / .26)
    card(canvas, image, 1260, (970, 540 - 90 * (1 - reveal)),
         yaw=8 * math.sin(moment * .35), pitch=-3, opacity=reveal)
    if 2.85 < moment < 3.35:
        pointer(canvas, (950, 640), True)
    if moment > 3.75:
        pointer(canvas, (1510, 345), 4 < moment < 4.25)
    text(canvas, (440, 940), 'WEATHER    GPU / RAM / CPU / CLOCK    MONTH', 20)


def sidebar_scene(canvas, moment):
    technical_field(canvas, moment + 12)
    caption(canvas, 4, 'SIDEBAR')
    image = sequence('sidebar', moment, 90)
    progress = ease(moment / .45)
    card(canvas, image, 410, (mix(370, 650, progress), 562),
         yaw=mix(14, 0, progress), roll=mix(-5, 0, progress))
    detail = image.crop((20, 720, 800, 1120))
    card(canvas, detail, 580, (1330, 580), yaw=-9, pitch=3,
         opacity=ease((moment - .5) / .4), outline=True)
    for index, label in enumerate(('NETWORK', 'BLUETOOTH', 'AUDIO', 'BRIGHTNESS', 'NOTIFICATIONS')):
        text(canvas, (1130, 795 + index * 34), label, 18, alpha=ease((moment - .5 - index * .1) / .3) * 220)


SETTINGS = [('general', 'GENERAL'), ('battery', 'BATTERY'),
            ('storage', 'STORAGE'), ('about', 'SYSTEM INFO')]


def settings_scene(canvas, moment):
    technical_field(canvas, moment + 15, True, .55)
    index = min(3, int(moment / 2.1))
    phase = moment - index * 2.1
    page, label = SETTINGS[index]
    caption(canvas, 5, 'SETTINGS / ' + label, True)
    arrival = ease(phase / .35)
    image = texture(str(ASSETS / f'settings-{page}.png'))
    card(canvas, image, 1190, (1050 + 100 * (1 - arrival), 575),
         yaw=mix(-10, 1, arrival), pitch=-2, opacity=arrival)
    for tab, (_, name) in enumerate(SETTINGS):
        text(canvas, (100, 330 + tab * 64), name, 19, True, 255 if tab == index else 100)
        if tab == index:
            ImageDraw.Draw(canvas).rectangle((80, 337 + tab * 64, 83, 354 + tab * 64), fill='#111111')


def outro(canvas, moment):
    technical_field(canvas, moment + 24, True, .6)
    specs = [('settings-general.png', 710, (550, 555), -18),
             ('calendar-framed/0149.png', 860, (1300, 390), 16),
             ('sidebar/0089.png', 240, (1380, 800), 12)]
    for file, width, center, yaw in specs:
        card(canvas, texture(str(ASSETS / file)), width,
             (center[0], center[1] + 20 * math.sin(moment * .7)), yaw=yaw, pitch=3,
             opacity=max(.1, 1 - ease((moment - .65) / 1)))
    if moment > .8:
        card(canvas, LOGO, 670, (960, 490), opacity=ease((moment - .8) / .65))
        text(canvas, (695, 645), 'ARCH LINUX / HYPRLAND / QUICKSHELL', 19, True,
             ease((moment - 1.05) / .6) * 255)


SCENES = [(0, 1.8, True, intro), (1.8, 4.8, False, desktops),
          (4.8, 7, False, volume), (7, 12, False, calendar_scene),
          (12, 15, False, sidebar_scene), (15, 23.4, True, settings_scene),
          (23.4, 26, True, outro)]


def render_frame(moment):
    for start, end, light, renderer in SCENES:
        if start <= moment < end:
            canvas = BACKGROUNDS[light].copy()
            renderer(canvas, moment - start)
            # Layer into RGB rather than retaining translucent drawing pixels.
            return Image.alpha_composite(BACKGROUNDS[light], canvas).convert('RGB')
    return BACKGROUNDS[True].convert('RGB')


def soundtrack():
    rate = 48000
    time_axis = np.arange(int(DURATION * rate)) / rate
    audio = np.zeros((len(time_axis), 2))
    random = np.random.default_rng(29)
    # Original, quiet mechanical sound design. No reference music is copied.
    drone = .018 * np.sin(math.tau * 55 * time_axis) + .008 * np.sin(math.tau * 82.5 * time_axis)
    envelope = np.minimum(1, time_axis / 1.2) * np.minimum(1, (DURATION - time_axis) / 1.6)
    audio[:] = (drone * envelope)[:, None]
    events = [start for start, *_ in SCENES] + [2.7, 3.6, 5.2, 5.6, 6.0, 10.0, 11.0, 17.1, 19.2, 21.3]
    for index, start in enumerate(events):
        length = int(.24 * rate)
        local = np.arange(length) / rate
        click = random.normal(0, 1, length) * np.exp(-local * 55) * .022
        bass = np.sin(math.tau * (78 * local - 35 * local ** 2)) * np.exp(-local * 18) * .045
        offset = int(start * rate)
        count = min(length, len(audio) - offset)
        pan = .3 + .4 * (index % 3) / 2
        audio[offset:offset + count, 0] += (click[:count] + bass[:count]) * pan
        audio[offset:offset + count, 1] += (click[:count] + bass[:count]) * (1 - pan)
    pcm = (np.clip(audio, -1, 1) * 32767).astype('<i2')
    path = ASSETS / 'original-soundtrack.wav'
    with wave.open(str(path), 'wb') as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(rate)
        output.writeframes(pcm.tobytes())
    return path


def render():
    audio = soundtrack()
    command = ['ffmpeg', '-y', '-v', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgb24',
               '-s', f'{WIDTH}x{HEIGHT}', '-r', str(FPS), '-i', '-', '-i', str(audio),
               '-c:v', 'libx264', '-preset', 'fast', '-crf', '18', '-pix_fmt', 'yuv420p',
               '-c:a', 'aac', '-b:a', '192k', '-movflags', '+faststart', '-shortest', str(OUTPUT)]
    process = subprocess.Popen(command, stdin=subprocess.PIPE)
    try:
        for frame_index in range(DURATION * FPS):
            moment = frame_index / FPS
            image = render_frame(moment)
            process.stdin.write(image.tobytes())
            if frame_index % (FPS * 2) == 0:
                print(f'{moment:.0f}s / {DURATION}s', flush=True)
        process.stdin.close()
        if process.wait() != 0:
            raise RuntimeError('Video encoder failed')
    finally:
        if process.poll() is None:
            process.terminate()
            process.wait()
    print(OUTPUT, flush=True)


if __name__ == '__main__':
    render()
