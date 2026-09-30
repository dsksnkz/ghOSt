# ghOSt

Graphical Hyprland Operating System Toolkit.

Quickshell rice with buddy codex

[Preview](https://dsksnkz.github.io/ghOSt/) · [Changes](docs/changes/2026-09-30-launcher.md)

![Staged ghOSt calendar](site/assets/calendar-performance.png)

## Current scope

Top rail, application launcher, calendar, radial performance instrument, audio, network, Bluetooth, media, battery and session panels. JetBrains Mono typography, Turret Road G, custom black/white icons and click-triggered motion.

The launcher searches installed desktop entries by name, generic name and keywords. Pins are saved in `$XDG_STATE_HOME/ghost/launcher.ini` (default `~/.local/state/ghost/launcher.ini`). It uses native desktop-entry execution, not shell-parsed search text.

CPU is measured from Linux counter deltas. GPU utilization is read only when selected. Processor means average clock frequency in MHz, scaled to the hardware maximum when available. Missing or stale readings show unavailable. Sampling stops when the calendar closes.

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

This explicitly installs into ~/.config/quickshell/ghost-bar, adds autostart and a layer animation rule, and disables Serpantinum's bar if present. Existing keyboard shortcuts, lock and Wi-Fi authentication still depend on Serpantinum; this is not a complete independent rice yet. The G control opens ghOSt's own launcher without replacing any shortcut. Settings helpers are pavucontrol, nm-connection-editor and blueman-manager.

The legacy restore command is ./install.sh --restore. It verifies tracked integration files before restoring the original snapshot; later edits require manual reconciliation. Backups are under ~/.local/state/ghost/backups. Staging alone needs no live rollback.

## Controls

- G opens Applications; type to search, Up/Down to select, Enter to open. Pins keep favorites first among equally ranked results.
- Workspace numbers switch workspace; scroll navigates.
- Clock opens Calendar; CPU / GPU / CLOCK switch the radial readout.
- Audio opens volume; scroll adjusts; right-click mutes.
- Network, Bluetooth, battery and media open their panels.
- Escape or click outside closes a native panel.
- Buttons support Tab focus and Return/Space activation.

## Verification

The 0.3.0 revision is staged, not activated on the laptop. It was rendered with the actual QML components in an isolated offscreen Quickshell instance. Native focus, application startup, multi-monitor placement and click-origin motion still need an opt-in live pass.

```sh
python3 -m unittest discover -s tests -v
node tests/test_launcher.cjs
```

See [verification](docs/verification.md) for evidence and limitations. Public previews use component-only renders. Private references remain excluded.
