"""The shaded folder is standalone, neutral grey and truly transparent."""
import io
from pathlib import Path
import subprocess
import unittest
import xml.etree.ElementTree as ET
from PIL import Image

ASSET = Path(__file__).resolve().parents[1] / "assets/folder-layered.svg"


class LayeredFolderTests(unittest.TestCase):
    def test_standalone_vector(self):
        root = ET.fromstring(ASSET.read_bytes())
        self.assertEqual(root.attrib["viewBox"], "0 0 256 256")
        self.assertFalse(any("href" in key or key.startswith("on")
                             for node in root.iter() for key in node.attrib))
        self.assertGreaterEqual(len(root.findall(".//{http://www.w3.org/2000/svg}linearGradient")), 3)

    def test_transparent_neutral_shading_at_small_and_large_sizes(self):
        for size in (32, 256):
            with self.subTest(size=size):
                data = subprocess.check_output(["rsvg-convert", "-w", str(size), "-h", str(size), str(ASSET)])
                image = Image.open(io.BytesIO(data)).convert("RGBA")
                bounds = image.getchannel("A").getbbox()
                self.assertTrue(bounds)
                self.assertGreater(bounds[0], 0)
                self.assertGreater(bounds[1], 0)
                self.assertLess(bounds[2], size)
                self.assertLess(bounds[3], size)
                raw = image.tobytes()
                pixels = [tuple(raw[index:index + 4]) for index in range(0, len(raw), 4)
                          if raw[index + 3] > 0]
                self.assertTrue(all(r == g == b for r, g, b, _ in pixels))
                self.assertGreater(len({r for r, _, _, alpha in pixels if alpha > 220}), 20)
                # Middle front panel must be lighter than the upper rear tab.
                self.assertGreater(image.getpixel((size // 2, int(size * .6)))[0],
                                   image.getpixel((int(size * .26), int(size * .29)))[0])
