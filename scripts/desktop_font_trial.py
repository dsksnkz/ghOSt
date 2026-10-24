#!/usr/bin/env python3
"""Try the installed Adwaita Sans in desktop apps, with a guarded restore."""
import argparse
import configparser
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

FAMILY = "Adwaita Sans"
GSETTINGS = (
    ("org.gnome.desktop.interface", "font-name", f"{FAMILY} 10"),
    ("org.gnome.desktop.interface", "document-font-name", f"{FAMILY} 10"),
    ("org.gnome.desktop.wm.preferences", "titlebar-font", f"{FAMILY} Bold 10"),
)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None


def ini_font(path, section, values):
    parser = configparser.ConfigParser(interpolation=None, strict=False)
    parser.optionxform = str
    parser.read(path)
    if not parser.has_section(section):
        parser.add_section(section)
    for key, value in values.items():
        parser.set(section, key, value)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w") as stream:
        parser.write(stream, space_around_delimiters=False)


def apply_trial():
    matched = subprocess.check_output(["fc-match", "-f", "%{family}", FAMILY], text=True)
    if FAMILY not in matched.split(","):
        raise SystemExit(f"{FAMILY} is not installed; nothing changed")
    home = Path.home()
    config = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
    snapshot = home / ".local/state/ghost/backups" / datetime.datetime.now().strftime("font-%Y%m%d-%H%M%S-%f")
    snapshot.mkdir(parents=True)
    gtk = [config / f"gtk-{version}/settings.ini" for version in ("3.0", "4.0")]
    qt = config / "qt6ct/qt6ct.conf"
    kde = config / "kdeglobals"
    alias = config / "fontconfig/conf.d/60-ghost-sans-trial.conf"
    record = {"files": [], "gsettings": []}
    for number, path in enumerate([*gtk, qt, kde, alias]):
        saved = snapshot / str(number)
        if path.exists():
            shutil.copy2(path, saved)
        record["files"].append({"path": str(path), "saved": str(saved) if path.exists() else None})
    for schema, key, value in GSETTINGS:
        before = subprocess.check_output(["gsettings", "get", schema, key], text=True).strip()
        record["gsettings"].append({"schema": schema, "key": key, "before": before, "after": "'" + value + "'"})
    manifest = snapshot / "manifest.json"
    manifest.write_text(json.dumps(record, indent=2) + "\n")
    manifest.chmod(0o600)
    for path in gtk:
        ini_font(path, "Settings", {"gtk-font-name": f"{FAMILY} 10"})
    ini_font(qt, "Fonts", {"general": f'"{FAMILY},10,-1,5,50,0,0,0,0,0"'})
    ini_font(kde, "General", {key: f"{FAMILY},10,-1,5,50,0,0,0,0,0" for key in
                             ("font", "menuFont", "toolBarFont", "smallestReadableFont", "taskbarFont")})
    ini_font(kde, "WM", {"activeFont": f"{FAMILY},10,-1,5,75,0,0,0,0,0"})
    alias.parent.mkdir(parents=True, exist_ok=True)
    alias.write_text('<?xml version="1.0"?>\n<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">\n'
                     '<fontconfig>\n  <alias><family>sans-serif</family><prefer><family>Adwaita Sans</family></prefer></alias>\n'
                     '  <alias><family>system-ui</family><prefer><family>Adwaita Sans</family></prefer></alias>\n</fontconfig>\n')
    for schema, key, value in GSETTINGS:
        subprocess.run(["gsettings", "set", schema, key, value], check=True)
    for entry in record["files"]:
        entry["installed"] = digest(Path(entry["path"]))
    manifest.write_text(json.dumps(record, indent=2) + "\n")
    print(f"Desktop font trial applied; restore with --restore {snapshot}")


def restore(snapshot):
    record = json.loads((snapshot / "manifest.json").read_text())
    for entry in record["files"]:
        if digest(Path(entry["path"])) != entry.get("installed"):
            raise SystemExit("File changed since trial; preserve later edits first: " + entry["path"])
    for entry in record["gsettings"]:
        current = subprocess.check_output(["gsettings", "get", entry["schema"], entry["key"]], text=True).strip()
        if current != entry["after"]:
            raise SystemExit("Font preference changed since trial; preserve it before restoring")
    for entry in record["files"]:
        path = Path(entry["path"])
        if entry["saved"]:
            shutil.copy2(entry["saved"], path)
        else:
            path.unlink()
    for entry in record["gsettings"]:
        subprocess.run(["gsettings", "set", entry["schema"], entry["key"], entry["before"]], check=True)
    print("Desktop font preferences restored; shell font is restored separately from its snapshot")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--apply", action="store_true")
    action.add_argument("--restore", type=Path)
    args = parser.parse_args()
    if args.apply:
        apply_trial()
    else:
        restore(args.restore)


if __name__ == "__main__":
    main()
