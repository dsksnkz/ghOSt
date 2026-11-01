"""The safe installer must ship every runtime file, without activating it."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

REPOSITORY = Path(__file__).resolve().parents[1]
SOURCE = REPOSITORY / "config/quickshell/ghost-bar"


class DistributionTests(unittest.TestCase):
    def test_complete_isolated_install(self):
        with tempfile.TemporaryDirectory(prefix="ghost-install-test-") as directory:
            root = Path(directory)
            target = root / "stage/ghost-bar"
            environment = dict(os.environ)
            environment.update(
                XDG_CONFIG_HOME=str(root / "config"),
                XDG_DATA_HOME=str(root / "data"),
                XDG_STATE_HOME=str(root / "state"),
            )
            subprocess.run(
                ["python3", str(REPOSITORY / "scripts/install.py"), "--stage-dir", str(target)],
                env=environment,
                check=True,
                capture_output=True,
            )
            for source in SOURCE.rglob("*"):
                if source.is_file() and "__pycache__" not in source.parts:
                    installed = target / source.relative_to(SOURCE)
                    self.assertEqual(source.read_bytes(), installed.read_bytes(), str(source))
            self.assertFalse((root / "config").exists(), "Staging changed active configuration")

    def test_activation_bundles_shell_config_and_restores_it(self):
        """Everything runs in a throwaway HOME with fake sudo, pacman and quickshell."""
        with tempfile.TemporaryDirectory(prefix="ghost-activate-test-") as directory:
            root = Path(directory)
            home, bin_dir = root / "home", root / "bin"
            config = home / ".config"
            (config / "hypr/config").mkdir(parents=True)
            bin_dir.mkdir()
            calls = root / "calls"
            for name in ("sudo", "pacman", "quickshell"):
                fake = bin_dir / name
                fake.write_text('#!/bin/sh\necho "$0 $*" >> "%s"\n' % calls)
                fake.chmod(0o755)
            (config / "hypr/config/autostart.lua").write_text("-- autostart\n")
            (config / "hypr/hyprland.lua").write_text("-- hyprland\n")
            (home / ".bashrc").write_text("# mine\n")
            environment = {"HOME": str(home), "PATH": str(bin_dir), "XDG_CONFIG_HOME": str(config),
                           "XDG_DATA_HOME": str(home / ".local/share"), "XDG_STATE_HOME": str(home / ".local/state")}
            script = str(REPOSITORY / "scripts/install.py")
            subprocess.run([sys.executable, script, "--activate", "--no-start"], env=environment, check=True, capture_output=True)
            log = calls.read_text()
            self.assertIn("pacman -S --needed fastfetch cava fish", log)
            self.assertIn("ghOSt", (home / ".bashrc").read_text())
            fastfetch = (config / "fastfetch/config.jsonc").read_text()
            self.assertIn(str(home), fastfetch)
            self.assertNotIn("/home/matte", fastfetch)
            self.assertNotIn("@HOME@", fastfetch)
            self.assertTrue((config / "fish/config.fish").exists() and (config / "cava/config").exists())
            self.assertTrue((config / "fastfetch/ascii/ghost.txt").exists())
            self.assertIn("ghost-animations.lua", (config / "hypr/hyprland.lua").read_text())
            self.assertTrue((config / "hypr/ghost-animations.lua").exists())
            self.assertIn("ghost-switcher.lua", (config / "hypr/hyprland.lua").read_text())
            subprocess.run([sys.executable, script, "--restore"], env=environment, check=True, capture_output=True)
            self.assertEqual((home / ".bashrc").read_text(), "# mine\n")
            self.assertEqual((config / "hypr/hyprland.lua").read_text(), "-- hyprland\n")
            self.assertFalse((config / "fastfetch/config.jsonc").exists())
            self.assertFalse((config / "hypr/ghost-animations.lua").exists())


if __name__ == "__main__":
    unittest.main()
