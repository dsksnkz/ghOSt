"""Font trial/restore touches only named UI preferences, never code fonts."""
import configparser
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("font_trial", ROOT / "scripts/desktop_font_trial.py")
TRIAL = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(TRIAL)


class FontTrialTests(unittest.TestCase):
    def test_apply_and_restore_preserve_original_files_and_monospace(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            config = home / "config"
            qt = config / "qt6ct/qt6ct.conf"
            qt.parent.mkdir(parents=True)
            qt.write_text('[Fonts]\nfixed="Code Font,10"\ngeneral="Old Sans,10"\n[Appearance]\nstyle=Breeze\n')
            before = qt.read_bytes()
            preferences = {(schema, key): "'Original Font 10'" for schema, key, _ in TRIAL.GSETTINGS}
            def read(command, **kwargs):
                return TRIAL.FAMILY if command[0] == "fc-match" else preferences[(command[2], command[3])]
            def write(command, **kwargs):
                preferences[(command[2], command[3])] = "'" + command[4].strip("'") + "'"
            with patch.dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(config)), \
                    patch.object(TRIAL.subprocess, "check_output", side_effect=read), \
                    patch.object(TRIAL.subprocess, "run", side_effect=write):
                TRIAL.apply_trial()
                self.assertIn('fixed="Code Font,10"', qt.read_text())
                self.assertIn("style=Breeze", qt.read_text())
                snapshot = next((home / ".local/state/ghost/backups").iterdir())
                TRIAL.restore(snapshot)
                self.assertEqual(qt.read_bytes(), before)
                self.assertFalse((config / "fontconfig/conf.d/60-ghost-sans-trial.conf").exists())
                self.assertTrue(all(value == "'Original Font 10'" for value in preferences.values()))

    def test_ini_font_preserves_other_settings(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "settings.ini"
            path.write_text("[Settings]\ngtk-icon-theme-name=ghOSt-Folders\ngtk-cursor-theme-size=20\n")
            TRIAL.ini_font(path, "Settings", {"gtk-font-name": "Adwaita Sans 10"})
            result = configparser.ConfigParser()
            result.read(path)
            self.assertEqual(result["Settings"]["gtk-icon-theme-name"], "ghOSt-Folders")
            self.assertEqual(result["Settings"]["gtk-cursor-theme-size"], "20")

    def test_restore_refuses_later_edits(self):
        with tempfile.TemporaryDirectory() as directory:
            snapshot = Path(directory)
            path = snapshot / "user-settings.ini"
            path.write_text("original")
            installed = TRIAL.digest(path)
            path.write_text("later user edit")
            (snapshot / "manifest.json").write_text(json.dumps({
                "files": [{"path": str(path), "saved": None, "installed": installed}], "gsettings": []
            }))
            with self.assertRaises(SystemExit):
                TRIAL.restore(snapshot)
            self.assertEqual(path.read_text(), "later user edit")


if __name__ == "__main__":
    unittest.main()
