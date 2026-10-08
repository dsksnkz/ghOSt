#!/usr/bin/env python3
"""Render three original, fixed, soft tactile pops. No recordings or random noise."""
import math
from pathlib import Path
import struct
import wave

OUTPUT = Path(__file__).resolve().parents[1] / 'config/quickshell/ghost-bar/sounds'

def render(name, frequency, duration):
    frames = []
    for index in range(round(48000 * duration)):
        t = index / 48000
        attack = min(1, t / .002)
        envelope = attack * math.exp(-t * 95) * (1 - t / duration)
        phase = 2 * math.pi * (frequency * t - frequency * .35 * t * t / duration)
        sample = .16 * envelope * (math.sin(phase) + .12 * math.sin(phase * 2))
        frames.append(struct.pack('<h', round(sample * 32767)))
    with wave.open(str(OUTPUT / (name + '.wav')), 'wb') as target:
        target.setparams((1, 2, 48000, 0, 'NONE', 'not compressed'))
        target.writeframes(b''.join(frames))

if __name__ == '__main__':
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for specification in (('rail', 680, .045), ('sidebar', 470, .055), ('settings', 840, .04)):
        render(*specification)
