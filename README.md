# ghOSt

Graphical Hyprland Operating System Toolkit.

[Preview](https://dsksnkz.github.io/ghOSt/) · [SVG icons](https://dsksnkz.github.io/ghOSt/icons.html) · [Progress](docs/PROGRESS.md)

61 standalone transparent SVG icons, each in black and white. [Usage and rebuilding](docs/icons.md).

![ghOSt calendar preview with sample readings](site/assets/calendar-frame.webp)

## Current scope

The current rail, sidebar, calendar and Settings runtime source, icons, fonts, helpers and installer are in this repository. [Source layout and development](docs/source.md). Local user preferences, SSIDs, private screenshots and recovery snapshots are not installation source and are deliberately excluded.

Top rail, application launcher, calendar with liquid GPU/RAM/CPU instrumentation, left sidebar, Settings, audio, network, Bluetooth, media, battery and a confirmation-based power panel. Measured Figma spacing, JetBrains Mono/Turret Road typography, monochrome SVG icons and click-triggered motion.

Settings has fourteen pages. PipeWire output/input selection, volume and mute; existing EasyEffects editor access; battery and opt-in local display-on history; sidebar widget visibility; laptop brightness; local wallpaper selection through a running awww daemon; ghOSt notification history; wireless/Bluetooth; reduced motion; storage and system information. Unavailable services are shown explicitly. The embedded equalizer band editor and independent lock remain pending.

Notifications use Python GObject/Gio (`python-gobject` on Arch). ghOSt becomes the standard Freedesktop server only when its name is vacant. With an existing server it observes new notifications and dismisses through the standard API, without taking ownership. New real notifications display a top-centered ghOSt popup in either mode. History starts with ghOSt and stays in memory; only DND preference is saved locally. In observation mode DND cannot silence another server's banners, and its actions must be used in that application. Another active server may also show its own banner; no existing service is stopped or replaced. The empty sidebar shows only “No more messages”. Escape or an outside click dismisses the open sidebar through dedicated keyboard/pointer routes.

Preferences use `$XDG_CONFIG_HOME/ghost/settings.json`. History is off by default and, when enabled, uses `$XDG_STATE_HOME/ghost/usage.json`. It counts observed display-on intervals while ghOSt runs, not user engagement; missed intervals are not backfilled. No history is uploaded.

Settings navigation keeps the original five categories together, with separate audio/power, desktop and system frames. Either profile picture opens a local image chooser; private copies are retained under `$XDG_CONFIG_HOME/ghost/profile-pictures/`, without altering the originals. The pencil opens a PC-name editor. Only an explicit Save requests a hostname change; validation and system permission errors are shown. No computer was renamed during verification.

The launcher searches installed desktop entries by name, generic name and keywords. Pins are saved in `$XDG_STATE_HOME/ghost/launcher.ini` (default `~/.local/state/ghost/launcher.ini`). It uses native desktop-entry execution, not shell-parsed search text.

CPU is measured from Linux counter deltas. GPU and RAM usage use system telemetry. The CPU diamond switches to average processor clock frequency in MHz. Missing or stale readings show unavailable; sampling stops when the calendar closes. London weather is configured in `config/ghost/weather.json` from the user's chosen location.

Calendar waves now animate on the GPU, with the same rounded silhouette and a
software fallback. Minute-only clocks, cached geometry and event-driven work-area
checks reduce background work. [Native output, measurements and recovery](docs/changes/2026-10-04-performance.md).
Development on the owner's laptop is now desktop-first, without a separate
visual preview or new website build; other installations remain explicitly opt-in.

## Stage

An Arch Linux, Hyprland, Quickshell with networking and bluetooth, and jetbrains as main font. NVIDIA utilization optionally uses nvidia-smi; supported DRM devices use gpu_busy_percent when available.

```sh
git clone https://github.com/dsksnkz/ghOSt.git
cd ghOSt
./install.sh
```

Default installation stages the complete runtime under ~/.local/share/ghost/staged/ghost-bar, excluding generated Python caches/logs. It does not start the shell or change the active rice, wallpaper, keybindings or autostart. Existing staged copies are backed up. An isolated installation test compares every runtime source/asset byte with its installed copy.

## Activate deliberately

```sh
./install.sh --activate
```

This installs ghOSt into `~/.config/quickshell/ghost-bar` and adds its own autostart. It does not edit another rice. If another bar is active, the bars may overlap; do not activate until that session is deliberately switched. This opt-in installer is not a complete independent-rice migration yet. The launcher and notification implementation are owned by ghOSt. Network/Bluetooth use standard Linux services; independent lock remains pending.

The legacy restore command is ./install.sh --restore. It verifies tracked integration files before restoring the original snapshot; later edits require manual reconciliation. Backups are under ~/.local/state/ghost/backups. Staging alone needs no live rollback.

## Controls

- The rail hides on its monitor's fullscreen workspace and returns afterward or on a normal workspace. Shortcuts and work-area reservation are unchanged.
- The menu control opens the sliding sidebar; the separate launcher searches applications by name or keywords. Pins keep favorites first among equally ranked results.
- The stationary triangle marks the center of a projected 3D workspace wheel. Numbers curve, recede and rotate while their hit targets stay fixed. Rapid input retargets the current pose; reduced motion snaps immediately. Scroll includes empty desktops 1–5 and populated higher desktops, accumulating fractional and multiple notches.
- Clock opens the whole calendar frame; clicking the CPU diamond switches it to processor clock.
- Audio opens volume; scroll adjusts; right-click mutes.
- Network, Bluetooth and battery open the sidebar. Its three-layer cards use standard Linux services, not another rice's shell.
- Sidebar and calendar gear controls open Settings. Search filters its navigation.
- Power opens a HUD. Sleep, log out, restart and shut down require a second confirmation click. Lock is unavailable until its independent configuration is complete.
- Escape or click outside closes a native panel.
- Settings navigation uses52px rows,16px group gaps and14px glyphs inside35px wells. The calendar is12% larger than the reference coordinate plane, uniformly scaled to fit the output.
- Buttons support Tab focus and Return/Space activation.

## Verification

2026-10-04: the user explicitly requested desktop-visible updates. Tested rail/sidebar/calendar/Settings corrections are deployed to the existing ghOSt profile; only ghOSt was restarted. Keybindings, wallpaper, autostart and legacy processes are preserved. The installer still requires deliberate activation on other machines. Public captures use labeled samples, not a remote desktop feed. Native loading, Settings mapping and notification observation were checked; physical pointer/GPU pixel parity, independent lock, further Figma layers and broader migration remain pending. [Latest change record and rollback](docs/changes/2026-10-04-desktop.md).

```sh
python3 -m unittest discover -s tests -v
node tests/test_launcher.cjs
```

See [verification](docs/verification.md) for evidence and limitations. Public previews use component-only renders. Private references remain excluded.
