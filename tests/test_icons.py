"""SVG structure, parity, rendering and genuine transparency checks."""
from pathlib import Path
import io
import json
import re
import subprocess
import unittest
import xml.etree.ElementTree as ET
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "config/quickshell/ghost-bar/icons"
MANIFEST = json.loads((ASSETS / "manifest.json").read_text())


class IconTests(unittest.TestCase):
    def test_shared_style_reaches_compatibility_icons(self):
        compat = (ASSETS.parent / "Icon.qml").read_text()
        self.assertIn("SvgIcon {", compat)
        self.assertNotIn("Canvas {", compat)
        self.assertNotIn("switch (", compat)
        self.assertEqual((ASSETS / "black/folder.svg").read_text().split("</title>")[1],
                         (ASSETS / "black/folder-rounded.svg").read_text().split("</title>")[1])
        for name in ("ethernet", "volume", "storage", "security", "play", "pin", "lightning"):
            self.assertIn("Q", (ASSETS / "black" / (name + ".svg")).read_text(), name)

    def test_rounded_folder_has_rounded_inside_corners(self):
        data = subprocess.check_output([
            "rsvg-convert", "-w", "240", "-h", "240",
            str(ASSETS / "black/folder-rounded.svg")])
        alpha = Image.open(io.BytesIO(data)).convert("RGBA").getchannel("A")
        # Curved cavity corners retain material where a square cutout wouldn't.
        for point in ((48, 132), (192, 132), (48, 192), (192, 192), (46, 114)):
            self.assertGreater(alpha.getpixel(point), 220, point)
        for point in ((120, 155), (80, 100)):
            self.assertEqual(alpha.getpixel(point), 0, point)

    def test_expected_coverage(self):
        names = {i["name"] for i in MANIFEST}
        required = set("settings wifi ethernet network bluetooth display brightness volume microphone notifications appearance wallpaper keyboard mouse touchpad accessibility language calendar clock battery power storage app accounts privacy security lock updates info search cpu gpu memory ghost".split())
        self.assertTrue(required <= names)
        self.assertEqual(len(names), len(MANIFEST))
        old = set(re.findall(r'case "([a-z-]+)":', (ASSETS.parent / "Icon.qml").read_text()))
        self.assertTrue(old <= names)

    def test_standalone_xml_and_web_parity(self):
        allowed = {"svg", "title", "path", "circle", "ellipse", "rect"}
        for icon in MANIFEST:
            for tone in ("black", "white"):
                with self.subTest(name=icon["name"], tone=tone):
                    file = ASSETS / tone / (icon["name"] + ".svg")
                    root = ET.fromstring(file.read_bytes())
                    self.assertEqual(root.attrib["viewBox"], "0 0 24 24")
                    self.assertEqual(root.attrib["stroke-width"], "2")
                    self.assertEqual(root.attrib["fill"], "none")
                    for element in root.iter():
                        self.assertIn(element.tag.split("}")[-1], allowed)
                        self.assertFalse(any(k.startswith("on") or "href" in k for k in element.attrib))
                    self.assertEqual(file.read_bytes(), (ROOT / "site/assets/icons" / tone / file.name).read_bytes())

    def test_rendered_transparency_bounds_and_tones(self):
        for icon in MANIFEST:
            for size in (24, 48):
                rendered = []
                for tone, rgb in (("black", (0, 0, 0)), ("white", (255, 255, 255))):
                    with self.subTest(name=icon["name"], tone=tone, size=size):
                        data = subprocess.check_output(["rsvg-convert", "-w", str(size), "-h", str(size), str(ASSETS / tone / (icon["name"] + ".svg"))])
                        image = Image.open(io.BytesIO(data)).convert("RGBA")
                        alpha = image.getchannel("A")
                        rendered.append(alpha.tobytes())
                        bbox = alpha.getbbox()
                        self.assertIsNotNone(bbox, "Empty artwork")
                        self.assertGreater(bbox[0], 0, "Clipped left")
                        self.assertGreater(bbox[1], 0, "Clipped top")
                        self.assertLess(bbox[2], size, "Clipped right")
                        self.assertLess(bbox[3], size, "Clipped bottom")
                        self.assertLess(sum(a > 0 for a in alpha.tobytes()), size * size * .75)
                        pixels = image.tobytes()
                        self.assertEqual({tuple(pixels[i:i+3]) for i in range(0, len(pixels), 4) if pixels[i+3] > 0}, {rgb})
                self.assertEqual(rendered[0], rendered[1], "Tone variants differ in shape")


if __name__ == "__main__":
    unittest.main()
