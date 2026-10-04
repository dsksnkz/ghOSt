"""Check the shipped GPU package/Qt uniform ABI without opening a preview."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SHADERS = ROOT / "config/quickshell/ghost-bar/shaders"
COMPILER = Path(os.environ.get("QSB", "/usr/lib/qt6/bin/qsb"))


class ShaderTests(unittest.TestCase):
    def test_source_and_fallback_are_distributed(self):
        self.assertTrue((SHADERS / "liquid.frag").is_file())
        self.assertGreater((SHADERS / "liquid.frag.qsb").stat().st_size, 1000)
        qml = (SHADERS.parent / "LiquidMeter.qml").read_text()
        self.assertIn("GraphicsInfo.Software", qml)
        self.assertIn("gpuLiquid.status !== ShaderEffect.Error", qml)
        self.assertIn("if (!meter.useGpu)", qml)
        self.assertIn("shaders/liquid.frag.qsb", qml)

    @unittest.skipUnless(COMPILER.is_file(), "Qt qsb unavailable; use the bundled package")
    def test_shader_rebuild_and_uniform_layout(self):
        with tempfile.TemporaryDirectory(prefix="ghost-shader-test-") as directory:
            package = Path(directory) / "liquid.frag.qsb"
            reflection = Path(directory) / "reflection.json"
            subprocess.run([
                str(COMPILER), "--qsbversion", "64", "--glsl", "100 es,120,150",
                "--hlsl", "50", "--msl", "12", "-o", str(package), str(SHADERS / "liquid.frag")
            ], check=True, capture_output=True)
            self.assertEqual(package.read_bytes(), (SHADERS / "liquid.frag.qsb").read_bytes())
            subprocess.run([
                str(COMPILER), "-x", "reflect", "-o", str(reflection), str(package)
            ], check=True, capture_output=True)
            data = json.loads(reflection.read_text())
            members = {member["name"]: member for member in data["uniformBlocks"][0]["members"]}
            self.assertEqual(members["qt_Matrix"]["offset"], 0)
            self.assertEqual(members["qt_Opacity"]["offset"], 64)
            self.assertEqual(members["meterSize"]["type"], "vec2")
            self.assertEqual(members["fillEnabled"]["offset"], 92)
            self.assertEqual(data["combinedImageSamplers"][0]["binding"], 1)
            self.assertEqual(data["inputs"][0]["name"], "qt_TexCoord0")


if __name__ == "__main__":
    unittest.main()
