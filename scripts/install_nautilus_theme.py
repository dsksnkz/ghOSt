#!/usr/bin/env python3
"""Build the existing rounded-folder overlay; explicitly opt in with --apply."""
import argparse
import configparser
import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess

REPO = Path(__file__).resolve().parents[1]
THEME = "ghOSt-Folders"
FOLDERS = (
    "folder", "folder-open", "folder-visiting", "folder-drag-accept",
    "folder-documents", "folder-download", "folder-downloads", "folder-music",
    "folder-pictures", "folder-videos", "folder-templates", "folder-publicshare",
    "folder-desktop", "folder-remote", "folder-saved-search", "user-home",
    "inode-directory",
)


def build_theme(destination):
    icons = destination / "scalable/places"
    icons.mkdir(parents=True, exist_ok=True)
    artwork = (REPO / "config/quickshell/ghost-bar/icons/white/folder-rounded.svg").read_text()
    for name in FOLDERS:
        (icons / f"{name}.svg").write_text(artwork)
        # GTK recolors symbolic icons for selected/disabled/sidebar states.
        (icons / f"{name}-symbolic.svg").write_text(artwork.replace(' color="#ffffff"', ""))
    (destination / "index.theme").write_text(
        "[Icon Theme]\nName=ghOSt Folders\nComment=Rounded ghOSt folder icons\n"
        "Inherits=breeze-dark,Adwaita,hicolor\nDirectories=scalable/places\n\n"
        "[scalable/places]\nSize=48\nMinSize=16\nMaxSize=512\n"
        "Type=Scalable\nContext=Places\n"
    )


def apply_theme(staged):
    home = Path.home()
    config = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
    data = Path(os.environ.get("XDG_DATA_HOME", home / ".local/share"))
    theme = data / "icons" / THEME
    css = config / "gtk-4.0/ghost-nautilus.css"
    gtk_css = config / "gtk-4.0/gtk.css"
    settings = [config / f"gtk-{version}/settings.ini" for version in ("3.0", "4.0")]
    backup = home / ".local/state/ghost/backups" / datetime.datetime.now().strftime("nautilus-%Y%m%d-%H%M%S-%f")
    backup.mkdir(parents=True)
    previous = {}
    for key in ("icon-theme", "color-scheme"):
        previous[key] = subprocess.check_output(
            ["gsettings", "get", "org.gnome.desktop.interface", key], text=True
        ).strip()
    files = []
    for number, path in enumerate([theme, css, gtk_css, *settings]):
        saved = backup / str(number)
        exists = path.exists()
        if exists:
            if path.is_dir():
                shutil.copytree(path, saved)
            else:
                shutil.copy2(path, saved)
        files.append({"path": str(path), "saved": str(saved) if exists else None})
    (backup / "before.json").write_text(json.dumps({"gsettings": previous, "files": files}, indent=2) + "\n")
    shutil.copytree(staged, theme, dirs_exist_ok=True)
    css.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(REPO / "config/ghost/nautilus.css", css)
    current_css = gtk_css.read_text() if gtk_css.exists() else ""
    import_line = '@import url("ghost-nautilus.css");'
    if import_line not in current_css:
        gtk_css.write_text(import_line + "\n" + current_css)
    for path in settings:
        parser = configparser.ConfigParser(interpolation=None)
        parser.optionxform = str
        parser.read(path)
        if not parser.has_section("Settings"):
            parser.add_section("Settings")
        parser.set("Settings", "gtk-icon-theme-name", THEME)
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w") as stream:
            parser.write(stream, space_around_delimiters=False)
    subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", THEME], check=True)
    subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", "prefer-dark"], check=True)
    print(f"Applied {THEME}; recovery snapshot: {backup}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--output", type=Path, default=REPO / ".local/nautilus-theme" / THEME)
    args = parser.parse_args()
    build_theme(args.output)
    if args.apply:
        apply_theme(args.output)
    else:
        print(f"Staged {args.output}; desktop unchanged")


if __name__ == "__main__":
    main()
