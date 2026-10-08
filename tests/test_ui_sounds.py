"""Fixed original pops stay quiet, short, distinct and distributable."""
import hashlib
from pathlib import Path
import struct
import unittest
import wave

SOUNDS = Path(__file__).resolve().parents[1] / "config/quickshell/ghost-bar/sounds"


class UiSoundTests(unittest.TestCase):
    def test_short_quiet_distinct_pcm(self):
        digests = set()
        for name, duration in (("rail", .045), ("sidebar", .055), ("settings", .04)):
            with self.subTest(surface=name), wave.open(str(SOUNDS / (name + ".wav"))) as audio:
                self.assertEqual((audio.getnchannels(), audio.getsampwidth(), audio.getframerate()),
                                 (1, 2, 48000))
                self.assertEqual(audio.getnframes(), round(duration * 48000))
                frames = audio.readframes(audio.getnframes())
                samples = struct.unpack("<" + "h" * (len(frames) // 2), frames)
                peak = max(abs(value) for value in samples) / 32767
                self.assertGreater(peak, .01)
                self.assertLess(peak, .2)
                self.assertEqual(samples[0], 0)
                digests.add(hashlib.sha256(frames).hexdigest())
        self.assertEqual(len(digests), 3)
