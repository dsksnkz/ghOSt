# ghOSt

Graphical Hyprland Operating System Toolkit.

A monochrome desktop shell for Arch Linux and Hyprland, built with Quickshell.

[Website](https://dsksnkz.github.io/ghOSt/) · [Source guide](docs/source.md) · [Progress](docs/PROGRESS.md)

## Components

- **Top rail:** workspaces and device controls. Scroll switches desktops; clicks open panels.
- **Calendar:** dates, London weather and device usage. Real system readings drive liquid meters.
- **Sidebar:** network, Bluetooth, audio, brightness and notifications. Uses standard Linux services.
- **Settings:** device and desktop preferences, grouped by function.
- **App launcher:** searches installed desktop entries; saves pinned favourites locally.
- **Motion:** grouped sidebar entrance and randomized calendar reveal, with reduced-motion support.

The website shows component captures and labeled browser motion demonstrations,
not remote desktop controls. [62 monochrome SVG icons](docs/icons.md) are reusable separately.

## Install

Requires Arch Linux, Hyprland, Quickshell with networking/Bluetooth/PipeWire,
Python 3 with GObject/Gio, and JetBrains Mono Nerd Font Mono.
Click sounds use Qt Multimedia (`qt6-multimedia`); hardware brightness uses
`brightnessctl` where a writable backlight exists.
The music rail uses installed `cava` for 15 background spectrum bars; no audio
samples are saved. Without Cava the background stays quiet.
Optional media-key and Super+I mappings are in [ghost-controls.lua](config/hypr/ghost-controls.lua).
Replace existing matching bindings deliberately; the installer does not add them.

```sh
git clone https://github.com/dsksnkz/ghOSt.git
cd ghOSt
./install.sh
```

Default installation stages the complete runtime without changing your desktop.
`./install.sh --activate` deliberately installs and starts ghOSt and adds its own
autostart. It does not disable another bar or replace shortcuts; switch existing
bars deliberately to avoid overlap.

`./install.sh --restore` restores verified integration snapshots. Later edits
may require reconciliation. Backups live in `~/.local/state/ghost/backups`.

## Limits and checks

Independent lock and an embedded equalizer remain pending. Notifications preserve
an existing server; observation-mode DND cannot silence that server's banners.
Unavailable readings and services are shown honestly. Private preferences,
notification history and recovery snapshots are not published.

[Verification](docs/verification.md) · [Install/source details](docs/source.md)

```sh
python3 -m unittest discover -s tests -v
node --test tests/test_site.mjs
```
