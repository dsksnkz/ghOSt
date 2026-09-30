# Verification

## 2026-09-30 / staged revision 0.3.0

See [launcher](changes/2026-09-30-launcher.md). Fifteen launcher assertions and six telemetry tests passed. Isolated Quickshell loaded the installed app catalogue and saved/reloaded pins. Search, selection bounds, preview-only dispatch and empty results were exercised through IPC. Screenshots are real QML renders, not native desktop interaction proof. Native keyboard input, application startup and multi-monitor focus remain pending explicit activation.

Both existing desktop shell PIDs survived unchanged; live keybinding JSON matched byte-for-byte and Hyprland reported no config errors. Runtime emitted only expected offscreen/Hyprland isolation warnings and two malformed-line warnings from existing desktop-entry files; no QML runtime errors remained. A staging-only installation succeeded. Web gallery launcher/search states and a 390px layout were checked in the browser with no horizontal overflow.

## 2026-09-29 / staged revision 0.2.1

See [telemetry repair](changes/2026-09-29-telemetry-repair.md) for current checks, clean screenshots and limits. Six telemetry tests pass; actual QML renders show measured CPU/GPU/clock data. The live desktop and keybindings were preserved. This revision has not been activated for a native interaction test.

The earlier 2026-09-29 publication incorrectly claimed real metrics and included application/chat screenshots. Its telemetry was a placeholder. The current revision corrects those claims and replaces the public assets. Old Git commits still retain the earlier images.

## Historical verification · 2026-09-28

Live environment: Arch Linux, Hyprland 0.56.2 (Lua configuration), Quickshell 0.3.1, HDMI-A-1 at 1920 × 1080 / 200 Hz.

- Cold Quickshell load completed without runtime warnings after fixes.
- Audio, network, Bluetooth, calendar, media, battery and session panels were opened and checked; logs remained free of runtime warnings.
- Screenshots were inspected for font rendering, content bounds, panel placement and material treatment.
- Live PipeWire volume, network connection, MPRIS metadata and UPower charge were read successfully.
- Existing keybinding file hash was identical before and after installation. An unrelated screenshot shortcut added earlier during development was preserved.
- Hyprland reported no configuration errors; only ghOSt reserves the top 48 pixels.
- Repeated installation produced one startup entry and retained the original backup.
- Shell syntax, Python compilation, entrypoint QML lint and whitespace checks passed.
- A three-second idle CPU sample registered 0 scheduler ticks; process RSS was approximately 186 MiB after exercising panels. This short sample is not a long-duration benchmark.

Wi-Fi reassociation, Bluetooth pairing, suspend/lock and logout/login were not exercised on the active user session. Multiple-monitor and narrow-screen behavior needs further live verification. No claim of zero possible bugs is made.

API references: [Quickshell panel exclusion](https://quickshell.org/docs/v0.3.1/types/Quickshell/PanelWindow/), [PipeWire service](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Pipewire/Pipewire/), [Hyprland layer rules](https://wiki.hypr.land/configuring/core/rules/layer-rules/).
