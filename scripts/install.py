#!/usr/bin/env python3
"""Stage or opt in to ghOSt without editing another rice's source."""
import argparse
import datetime
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--restore", action="store_true", help="restore the last pre-install snapshot")
parser.add_argument("--no-start", action="store_true", help="install without starting Quickshell")
parser.add_argument("--activate", action="store_true", help="explicitly install ghOSt and add its autostart")
parser.add_argument("--stage-dir", type=Path, help="optional isolated staging destination")
parser.add_argument("--no-packages", action="store_true", help="do not install missing packages")
parser.add_argument("--no-shell-config", action="store_true", help="keep existing bashrc, fish, fastfetch and cava configuration")
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
hyprland = config / "hypr/hyprland.lua"
command = launcher.with_name("ghost")
HYPR_SNIPPETS = ("ghost-animations.lua", "ghost-switcher.lua", "ghost-recovery.lua")
# Command or file -> Arch package for everything the shell and bundled configuration use.
PACKAGES = {"fastfetch": "fastfetch", "cava": "cava", "fish": "fish", "starship": "starship",
            "zoxide": "zoxide", "playerctl": "playerctl",
            # The lock screen authenticates through this PAM service.
            "/etc/pam.d/hyprlock": "hyprlock",
            "/usr/share/fonts/Adwaita/AdwaitaSans-Regular.ttf": "adwaita-fonts",
            "python:gi": "python-gobject", "wpctl": "wireplumber", "nmcli": "networkmanager",
            "bluetoothctl": "bluez-utils", "upower": "upower", "powerprofilesctl": "power-profiles-daemon",
            "brightnessctl": "brightnessctl", "xdg-open": "xdg-utils", "wl-copy": "wl-clipboard",
            "grim": "grim", "slurp": "slurp", "magick": "imagemagick", "awww-daemon": "awww",
            "pavucontrol": "pavucontrol", "blueman-manager": "blueman",
            "nm-connection-editor": "nm-connection-editor"}
SHELL_CONFIG = {
    "bashrc": home / ".bashrc",
    "fish/config.fish": config / "fish/config.fish",
    "fastfetch/config.jsonc": config / "fastfetch/config.jsonc",
    "fastfetch/media.sh": config / "fastfetch/media.sh",
    "fastfetch/ascii/ghost.txt": config / "fastfetch/ascii/ghost.txt",
    "cava/config": config / "cava/config",
}

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None

def run(*command):
    return subprocess.run(command, check=False, capture_output=True, text=True)

def copy_profile(destination):
    """Install the complete public runtime, excluding generated local caches."""
    shutil.copytree(
        repo / "config/quickshell/ghost-bar",
        destination,
        dirs_exist_ok=True,
        ignore=shutil.ignore_patterns("__pycache__", "*.pyc", "*.log"),
    )

def package_missing(requirement):
    if requirement.startswith("python:"):
        return importlib.util.find_spec(requirement[7:]) is None
    return not (Path(requirement).exists() if requirement.startswith("/") else shutil.which(requirement))

def install_packages():
    missing = [package for requirement, package in PACKAGES.items() if package_missing(requirement)]
    if not missing:
        return
    if args.no_packages:
        print("Missing packages: " + " ".join(missing))
        return
    if not shutil.which("pacman"):
        print("Install these packages with your package manager: " + " ".join(missing))
        return
    # Interactive on purpose: sudo asks in this terminal.
    if subprocess.run(["sudo", "pacman", "-S", "--needed", *missing], check=False).returncode:
        print("Packages not installed: " + " ".join(missing))

def snapshot(record, path):
    """Back up a file once, so --restore can put it back or remove it."""
    if any(entry["path"] == str(path) for entry in record["files"]):
        return
    backup = Path(record["backup"])
    saved = backup / (str(len(record["files"])) + "-" + path.name)
    if path.exists():
        shutil.copy2(path, saved)
    record["files"].append({"path": str(path), "saved": str(saved) if path.exists() else None, "bundled": True})

def install_shell_config(record):
    for relative, path in SHELL_CONFIG.items():
        snapshot(record, path)
        path.parent.mkdir(parents=True, exist_ok=True)
        text = (repo / "config/shell" / relative).read_text().replace("@HOME@", str(home))
        path.write_text(text)
        if path.suffix == ".sh":
            path.chmod(0o755)

def has_ghost_shortcuts():
    return any(path.exists() and "bar toggle launcher" in path.read_text() for path in (hyprland, keybinds))

def install_hypr_snippets(record):
    if not hyprland.exists():
        return
    snapshot(record, hyprland)
    # This configuration is no longer the untouched one Hyprland warns about.
    hyprland.write_text(re.sub(r"autogenerated\s*=\s*(true|1)", "autogenerated = false", hyprland.read_text()))
    # Decided before anything is appended: a config with its own routes keeps them.
    names = HYPR_SNIPPETS + (() if has_ghost_shortcuts() else ("ghost-keys.lua",))
    for name in names:
        path = config / "hypr" / name
        snapshot(record, path)
        shutil.copy2(repo / "config/hypr" / name, path)
        text = hyprland.read_text()
        if name not in text:
            hyprland.write_text(text.rstrip() + "\n\n-- ghOSt\ndofile(" + json.dumps(str(path)) + ")\n")

if args.restore:
    if not manifest.exists():
        raise SystemExit("No ghOSt installation snapshot found.")
    record = json.loads(manifest.read_text())
    for entry in record["files"]:
        expected = entry.get("installed_sha256")
        if expected and digest(Path(entry["path"])) != expected:
            raise SystemExit("File changed since installation; preserve those edits before restoring: " + entry["path"])
    # Stop only ghOSt's named configuration, and what would restart it.
    run(str(command), "stop") if command.exists() else run("quickshell", "kill", "-c", "ghost-bar")
    for entry in record["files"]:
        path = Path(entry["path"])
        if entry["saved"]:
            shutil.copy2(entry["saved"], path)
        elif path.exists() and (path == launcher or entry.get("bundled")):
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
    copy_profile(staged)
    print("ghOSt staged at " + str(staged))
    print("Live rice, wallpaper, keybindings and autostart were not changed.")
    print("To install and start ghOSt deliberately: ./install.sh --activate")
    raise SystemExit(0)

# A session that has never started Hyprland has no configuration yet.
created_hyprland = not (lua.exists() or conf.exists() or hyprland.exists())
if created_hyprland:
    hyprland.parent.mkdir(parents=True, exist_ok=True)
    stock = Path("/usr/share/hypr/hyprland.lua")
    hyprland.write_text(stock.read_text() if stock.exists() else "")
autostart = lua if lua.exists() else hyprland if hyprland.exists() else conf
before = digest(keybinds)
state.mkdir(parents=True, exist_ok=True)
record = json.loads(manifest.read_text()) if manifest.exists() else None
if record is None:
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = state / "backups" / stamp
    backup.mkdir(parents=True)
    entries = []
    for index, path in enumerate([autostart, launcher]):
        saved = backup / (str(index) + "-" + path.name)
        keep = path.exists() and not (created_hyprland and path == hyprland)
        if keep:
            shutil.copy2(path, saved)
        entries.append({"path": str(path), "saved": str(saved) if keep else None, "bundled": path == hyprland})
    if target.exists():
        shutil.copytree(target, backup / "ghost-bar")
    record = {"backup": str(backup), "files": entries, "keybinds_sha256": before}
    manifest.write_text(json.dumps(record, indent=2) + "\n")

install_packages()
target.mkdir(parents=True, exist_ok=True)
copy_profile(target)
if not args.no_shell_config:
    install_shell_config(record)
install_hypr_snippets(record)
launcher.parent.mkdir(parents=True, exist_ok=True)
launcher.write_text('#!/usr/bin/env bash\nexec ' + json.dumps(str(command)) + ' start\n')
launcher.chmod(0o755)
snapshot(record, command)
shutil.copy2(repo / "config/bin/ghost", command)
if autostart.suffix == ".lua":
    text = autostart.read_text()
    if "-- ghOSt top bar" not in text:
        text += '\n-- ghOSt top bar\nhl.on("hyprland.start", function()\n  hl.exec_cmd(' + json.dumps(str(launcher)) + ')\nend)\n'
    if "-- ghOSt motion" not in text:
        text += '\n-- ghOSt motion: the QML surfaces own their animation timing.\nhl.layer_rule({ name = "ghost-motion", match = { namespace = "ghost-(bar|panel|calendar|sidebar|rail-reservation)" }, no_anim = true })\n'
    if 'name = "ghost-settings"' not in text:
        text += '\n-- ghOSt Settings only.\nhl.window_rule({ name = "ghost-settings", match = { class = "org.quickshell", title = "ghOSt Settings" }, float = true, size = { 1024, 699 }, center = true, decorate = false, rounding = 0, opacity = "1 override" })\n'
    # The Settings wallpaper page needs its daemon; a configured desktop already has its own.
    if not has_ghost_shortcuts() and "awww-daemon" not in text:
        text += '\n-- ghOSt wallpaper\nhl.on("hyprland.start", function()\n  hl.exec_cmd("awww-daemon")\nend)\n'
    for rule in ("ghost-intro", "ghost-lock-exit-motion"):
        if 'name = "' + rule + '"' not in text:
            text += '\n' + next(line for line in (repo / 'config/hypr/ghost-rules.lua').read_text().splitlines() if 'name = "' + rule + '"' in line) + '\n'
    autostart.write_text(text)
else:
    text = conf.read_text()
    if "# ghOSt top bar" not in text:
        conf.write_text(text + '\n# ghOSt top bar\nexec-once = ' + str(launcher) + '\nmisc {\n    allow_session_lock_restore = true\n}\n')
if before != digest(keybinds):
    raise SystemExit("Keybinding verification failed.")
from install_intro import install as install_intro
install_intro()
for entry in record["files"]:
    entry["installed_sha256"] = digest(Path(entry["path"]))
manifest.write_text(json.dumps(record, indent=2) + "\n")
if not args.no_start:
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
        run("hyprctl", "reload")
        if shutil.which("awww-daemon") and "awww-daemon" in autostart.read_text():
            subprocess.Popen(["awww-daemon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        result = run(str(command), "shell")
        if result.returncode:
            raise SystemExit(result.stderr or result.stdout or "Quickshell failed to start; run ./install.sh --restore")
    else:
        print("ghOSt starts with your next Hyprland session.")
print("ghOSt installed.")
print("Backup: " + record["backup"])
print("Restore: ./install.sh --restore")
