"""The folder overlay reuses canonical artwork and keeps text contrast explicit."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("nautilus_theme", ROOT / "scripts/install_nautilus_theme.py")
THEME = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(THEME)


def luminance(color):
    channels = [int(color[index:index + 2], 16) / 255 for index in (1, 3, 5)]
    linear = [value / 12.92 if value <= 0.04045 else ((value + .055) / 1.055) ** 2.4 for value in channels]
    return sum(value * weight for value, weight in zip(linear, (.2126, .7152, .0722)))


class NautilusThemeTests(unittest.TestCase):
    def test_folder_aliases_share_existing_artwork(self):
        original = (ROOT / "config/quickshell/ghost-bar/icons/white/folder-rounded.svg").read_text()
        with tempfile.TemporaryDirectory() as directory:
            theme = Path(directory)
            THEME.build_theme(theme)
            for name in THEME.FOLDERS:
                self.assertEqual((theme / f"scalable/places/{name}.svg").read_text(), original)
                self.assertNotIn('color="#ffffff"', (theme / f"scalable/places/{name}-symbolic.svg").read_text())
            self.assertIn("Inherits=breeze-dark,Adwaita,hicolor", (theme / "index.theme").read_text())

    def test_foreground_background_pairs_exceed_aaa(self):
        for foreground, background in (("#f2f2f2", "#191919"), ("#f2f2f2", "#242424"),
                                       ("#f2f2f2", "#222222"), ("#f2f2f2", "#2d2d2d"),
                                       ("#191919", "#d6d6d6")):
            bright, dark = sorted([luminance(foreground), luminance(background)], reverse=True)
            self.assertGreater((bright + .05) / (dark + .05), 7)


if __name__ == "__main__":
    unittest.main()
