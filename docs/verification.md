# Verification · 2026-09-28

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
