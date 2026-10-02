#!/usr/bin/env python3
"""Stage or opt in to ghOSt without editing another rice's source."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--restore", action="store_true", help="restore the last pre-install snapshot")
parser.add_argument("--no-start", action="store_true", help="install without starting Quickshell")
parser.add_argument("--activate", action="store_true", help="explicitly install ghOSt and add its autostart")
parser.add_argument("--stage-dir", type=Path, help="optional isolated staging destination")
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
home = Path.home()
config = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
data = Path(os.environ.get("XDG_DATA_HOME", home / ".local/share"))
state = Path(os.environ.get("XDG_STATE_HOME", home / ".local/state")) / "ghost"
manifest = state / "install.json"
target = config / "quickshell/ghost-bar"
launcher = home / ".local/bin/ghost-bar"
lua = config / "hypr/config/autostart.lua"
conf = config / "hypr/hyprland.conf"
keybinds = config / "hypr/config/keybinds.lua"

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None

def run(*command):
    return subprocess.run(command, check=False, capture_output=True, text=True)

if args.restore:
    if not manifest.exists():
        raise SystemExit("No ghOSt installation snapshot found.")
    record = json.loads(manifest.read_text())
    for entry in record["files"]:
        expected = entry.get("installed_sha256")
        if expected and digest(Path(entry["path"])) != expected:
            raise SystemExit("File changed since installation; preserve those edits before restoring: " + entry["path"])
    # Stop only ghOSt's named configuration.
    run("quickshell", "kill", "-c", "ghost-bar")
    for entry in record["files"]:
        path = Path(entry["path"])
        if entry["saved"]:
            shutil.copy2(entry["saved"], path)
        elif path.exists() and path == launcher:
            path.unlink()
    print("Restored the previous bar and autostart. ghOSt source and snapshots are retained.")
    raise SystemExit(0)

if not args.activate:
    staged = args.stage_dir or data / "ghost/staged/ghost-bar"
    staged = staged.expanduser().resolve()
    if staged == target.resolve():
        raise SystemExit("Staging must not target the live configuration. Use --activate explicitly.")
    if staged.exists():
        backup = state / "backups" / ("stage-" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f"))
        shutil.copytree(staged, backup)
    shutil.copytree(repo / "config/quickshell/ghost-bar", staged, dirs_exist_ok=True)
    print("ghOSt staged at " + str(staged))
    print("Live rice, wallpaper, keybindings and autostart were not changed.")
    print("To install and start ghOSt deliberately: ./install.sh --activate")
    raise SystemExit(0)

if not lua.exists() and not conf.exists():
    raise SystemExit("No supported Hyprland autostart configuration found; no files changed.")
before = digest(keybinds)
state.mkdir(parents=True, exist_ok=True)
record = json.loads(manifest.read_text()) if manifest.exists() else None
if record is None:
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = state / "backups" / stamp
    backup.mkdir(parents=True)
    entries = []
    for index, path in enumerate([lua if lua.exists() else conf, launcher]):
        saved = backup / (str(index) + "-" + path.name)
        if path.exists():
            shutil.copy2(path, saved)
        entries.append({"path": str(path), "saved": str(saved) if path.exists() else None})
    if target.exists():
        shutil.copytree(target, backup / "ghost-bar")
    record = {"backup": str(backup), "files": entries, "keybinds_sha256": before}
    manifest.write_text(json.dumps(record, indent=2) + "\n")

target.mkdir(parents=True, exist_ok=True)
shutil.copytree(repo / "config/quickshell/ghost-bar", target, dirs_exist_ok=True)
launcher.parent.mkdir(parents=True, exist_ok=True)
launcher.write_text('#!/usr/bin/env bash\nexec quickshell -d -n -c ghost-bar "$@"\n')
launcher.chmod(0o755)
if lua.exists():
    text = lua.read_text()
    if "-- ghOSt top bar" not in text:
        text += '\n-- ghOSt top bar\nhl.on("hyprland.start", function()\n  hl.exec_cmd(' + json.dumps(str(launcher)) + ')\nend)\n'
    if "-- ghOSt motion" not in text:
        text += '\n-- ghOSt motion: the QML surfaces own their animation timing.\nhl.layer_rule({ name = "ghost-motion", match = { namespace = "ghost-(bar|panel)" }, no_anim = true })\n'
    lua.write_text(text)
else:
    text = conf.read_text()
    if "# ghOSt top bar" not in text:
        conf.write_text(text + '\n# ghOSt top bar\nexec-once = ' + str(launcher) + '\n')
if before != digest(keybinds):
    raise SystemExit("Keybinding verification failed.")
for entry in record["files"]:
    entry["installed_sha256"] = digest(Path(entry["path"]))
manifest.write_text(json.dumps(record, indent=2) + "\n")
if not args.no_start:
    result = run(str(launcher))
    if result.returncode:
        raise SystemExit(result.stderr or result.stdout or "Quickshell failed to start; run ./install.sh --restore")
print("ghOSt installed. Keybindings unchanged.")
print("Backup: " + record["backup"])
print("Restore: ./install.sh --restore")
