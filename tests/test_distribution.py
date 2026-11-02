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
            self.assertIn("fish_add_path -g $HOME/.local/bin", (config / "fish/config.fish").read_text())
            self.assertTrue((config / "fastfetch/ascii/ghost.txt").exists())
            self.assertIn("ghost-animations.lua", (config / "hypr/hyprland.lua").read_text())
            self.assertTrue((config / "hypr/ghost-animations.lua").exists())
            self.assertIn("ghost-switcher.lua", (config / "hypr/hyprland.lua").read_text())
            command = home / ".local/bin/ghost"
            self.assertTrue(os.access(command, os.X_OK))
            subprocess.run([sys.executable, script, "--restore"], env=environment, check=True, capture_output=True)
            self.assertEqual((home / ".bashrc").read_text(), "# mine\n")
            self.assertEqual((config / "hypr/hyprland.lua").read_text(), "-- hyprland\n")
            self.assertFalse((config / "fastfetch/config.jsonc").exists())
            self.assertFalse((config / "hypr/ghost-animations.lua").exists())
            self.assertFalse(command.exists())

    def run_package_step(self, helpers):
        with tempfile.TemporaryDirectory(prefix="ghost-packages-test-") as directory:
            root = Path(directory)
            home, bin_dir = root / "home", root / "bin"
            home.mkdir()
            bin_dir.mkdir()
            calls = root / "calls"
            for name in ("sudo", "pacman", "quickshell") + helpers:
                fake = bin_dir / name
                fake.write_text('#!/bin/sh\necho "%s $*" >> "%s"\n' % (name, calls))
                fake.chmod(0o755)
            environment = {"HOME": str(home), "PATH": str(bin_dir)}
            result = subprocess.run([sys.executable, str(REPOSITORY / "scripts/install.py"), "--activate", "--no-start"],
                                    env=environment, check=True, capture_output=True, text=True)
            return calls.read_text(), result.stdout

    def test_aur_packages_never_reach_pacman(self):
        calls, _ = self.run_package_step(("yay",))
        pacman = next(line for line in calls.splitlines() if line.startswith("sudo pacman"))
        self.assertNotIn("crunchycleaner", pacman)
        self.assertIn("yay -S --needed crunchycleaner-bin", calls)

    def test_aur_packages_are_listed_without_a_helper(self):
        calls, output = self.run_package_step(())
        self.assertNotIn("crunchycleaner", calls)
        self.assertIn("Install these from the AUR: crunchycleaner-bin", output)

    def activate(self, root, home):
        bin_dir = root / "bin"
        bin_dir.mkdir()
        for name in ("sudo", "pacman", "quickshell"):
            fake = bin_dir / name
            fake.write_text("#!/bin/sh\nexit 0\n")
            fake.chmod(0o755)
        config = home / ".config"
        environment = {"HOME": str(home), "PATH": str(bin_dir), "XDG_CONFIG_HOME": str(config),
                       "XDG_DATA_HOME": str(home / ".local/share"), "XDG_STATE_HOME": str(home / ".local/state")}
        script = str(REPOSITORY / "scripts/install.py")
        subprocess.run([sys.executable, script, "--activate", "--no-start"], env=environment, check=True, capture_output=True)
        return lambda: subprocess.run([sys.executable, script, "--restore"], env=environment, check=True, capture_output=True)

    def test_activation_on_a_stock_config(self):
        with tempfile.TemporaryDirectory(prefix="ghost-stock-test-") as directory:
            root = Path(directory)
            home = root / "home"
            main = home / ".config/hypr/hyprland.lua"
            main.parent.mkdir(parents=True)
            main.write_text("-- stock\nhl.config({ autogenerated = true })\n")
            restore = self.activate(root, home)
            text = main.read_text()
            for expected in ("ghost-bar", "ghost-keys.lua", "ghost-recovery.lua", "awww-daemon", "ghost-settings"):
                self.assertIn(expected, text)
            self.assertNotIn("autogenerated = true", text)
            launcher = (home / ".local/bin/ghost-bar").read_text()
            self.assertIn("ghost", launcher)
            self.assertIn("start", launcher)
            restore()
            self.assertEqual(main.read_text(), "-- stock\nhl.config({ autogenerated = true })\n")
            self.assertFalse((home / ".config/hypr/ghost-keys.lua").exists())

    def test_activation_without_any_config_and_restore_removes_it(self):
        with tempfile.TemporaryDirectory(prefix="ghost-empty-test-") as directory:
            root = Path(directory)
            home = root / "home"
            home.mkdir()
            restore = self.activate(root, home)
            main = home / ".config/hypr/hyprland.lua"
            self.assertIn("ghost-bar", main.read_text())
            restore()
            self.assertFalse(main.exists())

    def test_activation_keeps_existing_ghost_shortcuts(self):
        with tempfile.TemporaryDirectory(prefix="ghost-keys-test-") as directory:
            root = Path(directory)
            home = root / "home"
            hypr = home / ".config/hypr"
            (hypr / "config").mkdir(parents=True)
            (hypr / "hyprland.lua").write_text("-- main\n")
            (hypr / "config/autostart.lua").write_text("-- autostart\n")
            keys = 'hl.bind("SUPER + Space", hl.dsp.exec_cmd("quickshell ipc -c ghost-bar call bar toggle launcher"))\n'
            (hypr / "config/keybinds.lua").write_text(keys)
            self.activate(root, home)
            self.assertNotIn("ghost-keys.lua", (hypr / "hyprland.lua").read_text())
            self.assertEqual((hypr / "config/keybinds.lua").read_text(), keys)
            self.assertNotIn("awww-daemon", (hypr / "config/autostart.lua").read_text())

    def supervise_with(self, root, script):
        """Runs `ghost supervise` against a fake quickshell and a live fake Hyprland."""
        (root / "run").mkdir()
        for name, body in (("quickshell", script), ("sleep", "#!/bin/sh\nexit 0\n"),
                           ("hyprctl", '#!/bin/sh\n[ "$1" = monitors ] && echo "Monitor HDMI-A-1 (ID 0):"\nexit 0\n')):
            fake = root / name
            fake.write_text(body)
            fake.chmod(0o755)
        environment = dict(os.environ, PATH=f"{root}:/usr/bin:/bin", XDG_RUNTIME_DIR=str(root / "run"),
                           XDG_STATE_HOME=str(root / "state"))
        subprocess.run([str(REPOSITORY / "config/bin/ghost"), "supervise"], env=environment, check=True, timeout=20)
        return (root / "runs").read_text().splitlines()

    def test_supervisor_restarts_after_any_unrequested_exit(self):
        with tempfile.TemporaryDirectory(prefix="ghost-supervise-test-") as directory:
            root = Path(directory)
            # Crash, clean exit nobody asked for, then a requested stop.
            runs = self.supervise_with(root, """#!/bin/bash
echo run >> "%s/runs"
case "$(wc -l < "%s/runs")" in
    1) exit 139 ;;
    2) exit 0 ;;
    *) echo "INFO: Exiting due to IPC request."; exit 0 ;;
esac
""" % (root, root))
            self.assertEqual(len(runs), 3)
            log = (root / "state/ghost/shell-restarts.log").read_text()
            self.assertIn("exit 139", log)
            self.assertIn("exit 0", log)

    @unittest.skipUnless(Path("/etc/pam.d/hyprlock").exists(), "needs the hyprlock PAM service")
    def test_lock_client_returns_after_a_crash(self):
        with tempfile.TemporaryDirectory(prefix="ghost-lock-test-") as directory:
            root = Path(directory)
            (root / "run").mkdir()
            for name, body in (("quickshell", """#!/bin/bash
echo "$*" >> "%s/runs"
[ "$(wc -l < "%s/runs")" -ge 3 ] && exit 0
exit 139
""" % (root, root)), ("sleep", "#!/bin/sh\nexit 0\n"), ("hyprctl", "#!/bin/sh\nexit 0\n")):
                fake = root / name
                fake.write_text(body)
                fake.chmod(0o755)
            environment = dict(os.environ, PATH=f"{root}:/usr/bin:/bin", XDG_RUNTIME_DIR=str(root / "run"))
            result = subprocess.run([str(REPOSITORY / "config/bin/ghost"), "lock"], env=environment, timeout=20)
            self.assertEqual(result.returncode, 0)
            self.assertEqual(len((root / "runs").read_text().splitlines()), 3)

    def test_ghost_shell_waits_for_exit_then_restarts(self):
        """Uses a fake quickshell: the old instance takes two checks to exit."""
        with tempfile.TemporaryDirectory(prefix="ghost-command-test-") as directory:
            root = Path(directory)
            fake = root / "quickshell"
            fake.write_text("""#!/bin/bash
echo "$*" >> "%s/calls"
count="%s/checks"
if [ "$1" = list ]; then
    echo x >> "$count"
    [ "$(wc -l < "$count")" -ge 3 ] && echo "No running instances." || echo "Instance abc"
fi
exit 0
""" % (root, root))
            fake.chmod(0o755)
            environment = dict(os.environ, PATH=f"{root}:/usr/bin:/bin")
            result = subprocess.run([str(REPOSITORY / "config/bin/ghost"), "shell"], env=environment,
                                    capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("restarted", result.stdout)
            calls = (root / "calls").read_text().splitlines()
            self.assertEqual(calls[0], "kill -c ghost-bar")
            self.assertIn("ipc -c ghost-bar call bar status", calls[1:])
            usage = subprocess.run([str(REPOSITORY / "config/bin/ghost"), "other"], env=environment,
                                   capture_output=True, text=True, timeout=10)
            self.assertEqual(usage.returncode, 2)
            self.assertIn("ghost shell", usage.stderr)


if __name__ == "__main__":
    unittest.main()
