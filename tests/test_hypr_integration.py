"""Published Lua snippets are syntax checked and evaluated only against a stub."""
import os
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
SNIPPETS = ("ghost-rules", "ghost-autostart", "ghost-controls", "ghost-migration", "ghost-lock")


class HyprlandIntegration(unittest.TestCase):
    @unittest.skipUnless(shutil.which("lua") and shutil.which("luac"), "Lua syntax tools unavailable")
    def test_syntax_and_recorded_api(self):
        for name in SNIPPETS:
            subprocess.run(["luac", "-p", str(ROOT / f"config/hypr/{name}.lua")], check=True)
        environment = dict(os.environ, HOME="/tmp/ghost sample home", XDG_CONFIG_HOME="/tmp/ghost sample config")
        result = subprocess.run(["lua", str(ROOT / "tests/hypr-integration.lua"), str(ROOT)],
                                check=True, text=True, capture_output=True, env=environment)
        self.assertIn("PASS: scoped Hyprland rules", result.stdout)

    def test_no_local_paths_or_legacy_runtime(self):
        for name in SNIPPETS:
            source = (ROOT / f"config/hypr/{name}.lua").read_text()
            for private_or_legacy in ("/home/matte", "serpantinum", "tempered", "eDP-", "HDMI-A-", "hl.monitor", "hl.permission"):
                self.assertNotIn(private_or_legacy.lower(), source.lower())


if __name__ == "__main__":
    unittest.main()
