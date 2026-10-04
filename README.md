# ghOSt

Graphical Hyprland Operating System Toolkit.

[Preview](https://dsksnkz.github.io/ghOSt/) · [SVG icons](https://dsksnkz.github.io/ghOSt/icons.html) · [Progress](docs/PROGRESS.md)

61 standalone transparent SVG icons, each in black and white. [Usage and rebuilding](docs/icons.md).

![ghOSt calendar preview with sample readings](site/assets/calendar-frame.webp)

## Current scope

Top rail, application launcher, calendar with liquid GPU/RAM/CPU instrumentation, left sidebar, Settings, audio, network, Bluetooth, media, battery and a confirmation-based power panel. Measured Figma spacing, JetBrains Mono/Turret Road typography, monochrome SVG icons and click-triggered motion.

Settings has fourteen pages. PipeWire output/input selection, volume and mute; existing EasyEffects editor access; battery and opt-in local display-on history; sidebar widget visibility; laptop brightness; local wallpaper selection through a running awww daemon; independent Swaync notifications; wireless/Bluetooth; reduced motion; storage and system information. Unavailable services are shown explicitly. The equalizer band editor, independent lock and notification service are not implemented yet.

Preferences use `$XDG_CONFIG_HOME/ghost/settings.json`. History is off by default and, when enabled, uses `$XDG_STATE_HOME/ghost/usage.json`. It counts observed display-on intervals while ghOSt runs, not user engagement; missed intervals are not backfilled. No history is uploaded.

Settings navigation keeps the original five categories together, with separate audio/power, desktop and system frames. Either profile picture opens a local image chooser; private copies are retained under `$XDG_CONFIG_HOME/ghost/profile-pictures/`, without altering the originals. The pencil opens a PC-name editor. Only an explicit Save requests a hostname change; validation and system permission errors are shown. No computer was renamed during verification.

The launcher searches installed desktop entries by name, generic name and keywords. Pins are saved in `$XDG_STATE_HOME/ghost/launcher.ini` (default `~/.local/state/ghost/launcher.ini`). It uses native desktop-entry execution, not shell-parsed search text.

CPU is measured from Linux counter deltas. GPU and RAM usage use system telemetry. The CPU diamond switches to average processor clock frequency in MHz. Missing or stale readings show unavailable; sampling stops when the calendar closes. London weather is configured in `config/ghost/weather.json` from the user's chosen location.

## Stage

An Arch Linux, Hyprland, Quickshell with networking and bluetooth, and jetbrains as main font. NVIDIA utilization optionally uses nvidia-smi; supported DRM devices use gpu_busy_percent when available.

```sh
git clone https://github.com/dsksnkz/ghOSt.git
cd ghOSt
./install.sh
```

Default installation stages a separate copy under ~/.local/share/ghost/staged/ghost-bar. It does not start the shell or change the active rice, wallpaper, keybindings or autostart. Existing staged copies are backed up.

## Activate deliberately

```sh
./install.sh --activate
```

This installs ghOSt into `~/.config/quickshell/ghost-bar` and adds its own autostart. It does not edit another rice. If another bar is active, the bars may overlap; do not activate until that session is deliberately switched. This opt-in installer is not a complete independent-rice migration yet. The launcher is native to ghOSt. Network and Bluetooth controls use standard system utilities where needed; the independent lock and notifications surfaces remain pending.

The legacy restore command is ./install.sh --restore. It verifies tracked integration files before restoring the original snapshot; later edits require manual reconciliation. Backups are under ~/.local/state/ghost/backups. Staging alone needs no live rollback.

## Controls

- The menu control opens the sliding sidebar; the separate launcher searches applications by name or keywords. Pins keep favorites first among equally ranked results.
- The stationary triangle marks the center of the sliding workspace numbers. Scroll includes all desktops 1–5 and populated higher desktops, with accumulated notches.
- Clock opens the whole calendar frame; clicking the CPU diamond switches it to processor clock.
- Audio opens volume; scroll adjusts; right-click mutes.
- Network, Bluetooth and battery open the sidebar. Its three-layer cards use standard Linux services, not another rice's shell.
- Sidebar and calendar gear controls open Settings. Search filters its navigation.
- Power opens a HUD. Sleep, log out, restart and shut down require a second confirmation click. Lock is unavailable until its independent configuration is complete.
- Escape or click outside closes a native panel.
- Buttons support Tab focus and Return/Space activation.

## Verification

The earlier user-authorized rail-autostart transition is separate from this update. Current Settings, sidebar and typography changes were verified only in an isolated preview; the running desktop, keybindings and autostart were not changed. The installer stages by default. Public previews are actual Quickshell renders with labeled sample values. Physical Wayland input, independent lock/notification history, 3D workspace motion and broader migration remain pending. See [latest change record](docs/changes/2026-10-04-settings.md).

```sh
python3 -m unittest discover -s tests -v
node tests/test_launcher.cjs
```

See [verification](docs/verification.md) for evidence and limitations. Public previews use component-only renders. Private references remain excluded.
