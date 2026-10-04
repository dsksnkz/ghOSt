"""The safe installer must ship every runtime file, without activating it."""
import os
from pathlib import Path
import subprocess
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


if __name__ == "__main__":
    unittest.main()
