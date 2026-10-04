# Verification

## 2026-10-04 / native performance pass

50 Python tests, exact cached-wave geometry, corner/wheel and15 launcher
assertions pass. Native GPU shaders compile; all three moving phases and stopped
closed states are read through the installed shell. Component-only desktop
captures retain the reference material and composition. Short native CPU samples
and their limits are in [the change record](changes/2026-10-04-performance.md).
No separate visual preview/site is built after the user's latest instruction.
Earlier isolated checks in this same pass preceded that instruction; they are
not presented as native input or GPU pixel-parity proof.

2026-10-04 desktop-visible pass:45 Python tests including isolated session-bus notification protocol/ownership tests;15 launcher assertions, JS wheel checks,14 QML Settings pages/flows, sidebar radii/fonts/motion and calendar/wheel animation checks pass. Native ghOSt loading,1024×699 Settings mapping and real notification observation were checked; stale Settings-focus transition fixed. Existing service ownership, shortcuts/autostart and wallpaper preserved. [Evidence and limits](changes/2026-10-04-desktop.md). This supersedes earlier staging-only verification for the explicitly authorized ghOSt surfaces, not the broader pending migration.

## 2026-10-04 · Workspace wheel

41 Python tests, 15 launcher assertions, deterministic JS ring/projection checks and actual QML transient depth/rotation, fixed-triangle, wraparound, partial/multiple-notch, retargeting and reduced-motion checks pass. Prior Settings/sidebar/calendar regression passes. Actual screenshots and native QML motion frames captured; installer stages in an isolated directory. No live pointer/keyboard dispatch or activation. [Evidence and limits](changes/2026-10-04-workspace-wheel.md).

## 2026-10-04 / isolated Settings corrections

41 Python tests,15 launcher assertions,61 two-tone icon checks,14 Settings pages plus profile/name/search flows, runtime sidebar/rail properties and calendar motion/weather/reduced-motion checks passed. Isolated staging installer succeeds. Real Qt popup overlay is included in captures. Both portraits visibly change in fixtures; original preservation/private file permissions are unit-tested. Invalid PC names cannot dispatch; permission errors cannot fake success. Native image picker, real hostname setter and power actions were not exercised. Active keybinding/autostart hashes match starting values; Hyprland config errors empty. [Evidence and limits](changes/2026-10-04-settings.md).

## 2026-10-03 / current two-desktop reference pass

36 Python tests, 15 launcher assertions, all fourteen isolated Settings pages, exact preview origin/size/navigation height/plain font loading, sidebar grouping/fades, and isolated calendar ratio/reveal/weather/reduced-motion checks pass. Default staging install succeeds. [Evidence and remaining gaps](changes/2026-10-03-exact-figma.md). No native activation or 100% raster parity claim. Calendar-to-Settings invalid-context warning was repaired; checks use a fresh capture timestamp.

## 2026-10-03 / Settings and native rail transition

36 Python tests, 15 launcher assertions, isolated Settings/sidebar geometry/captures and calendar motion checks pass. New native Settings/window rule, rail transparency/work-area reservation and old rail removal were checked. Native ghOSt log has no QML warnings; configuration errors are empty; bind file and JSON hashes match pre-transition values. Startup persistence is configured, not reboot-tested. [Detailed evidence, screenshots and honest gaps](changes/2026-10-03-settings-polish.md). No destructive actions or hardware/service setters ran.

## 2026-10-03 / Figma property inspection

The latest direct request authorized launching rail, calendar and sidebar. [Specification and limits](figma-spec.md), [current progress](PROGRESS.md). Fifteen Python tests, fifteen launcher assertions, icon parity and isolated randomized reveal/weather/ratio tests passed. Live QML loading, simultaneous sidebar/calendar state, screenshots and layer geometry were inspected. Existing binds were unchanged and Hyprland configuration errors empty. This supersedes the earlier sidebar approval status below. Physical pointer automation, notification history and the independent lock remain unverified or unfinished; no disruptive action was tested.

## 2026-10-03 / calendar, rail and staged sidebar

See [frame change record](changes/2026-10-03-frames.md) and [progress](PROGRESS.md). The user explicitly approved live activation of calendar and rail only. The sidebar is staged and independently rendered with labeled sample device names; it is not active on the desktop pending separate approval. Fifteen Python tests, fifteen launcher assertions, an isolated calendar animation check, native Quickshell reload/layer inspection and desktop/mobile website screenshots passed. `hyprctl configerrors` was empty; the live keybind JSON SHA-256 was unchanged before/after. Actual user pointer clicks, independent lock/notification handling and completion of the old-rice audit remain unverified. No session or power action was executed.

## 2026-09-30 / staged revision 0.3.0

See [launcher](changes/2026-09-30-launcher.md). Fifteen launcher assertions and six telemetry tests passed. Isolated Quickshell loaded the installed app catalogue and saved/reloaded pins. Search, selection bounds, preview-only dispatch and empty results were exercised through IPC. Screenshots are real QML renders, not native desktop interaction proof. Native keyboard input, application startup and multi-monitor focus remain pending explicit activation.

Both existing desktop shell PIDs survived unchanged; live keybinding JSON matched byte-for-byte and Hyprland reported no config errors. Runtime emitted only expected offscreen/Hyprland isolation warnings and two malformed-line warnings from existing desktop-entry files; no QML runtime errors remained. A staging-only installation succeeded. Web gallery launcher/search states and a 390 px layout were checked in the browser with no horizontal overflow.

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
# SVG icon verification / 2026-10-02

60 icons, 120 tone variants, mirrored byte-for-byte between shell and website. XML safety, transparent bounds, pure black/white pixels, and identical tone alpha masks passed at 24 px and 48 px (240 renders). All 120 images loaded in isolated offscreen Quickshell. Nine Python tests and 15 launcher assertions passed. Browser checks covered all 60 loaded images, both tone modes, hardware search (3 results), empty search, and 390 px layout without horizontal overflow. Staging installer passed. Existing desktop keybindings and active rice were preserved.

Screenshots and limitations: [2026-10-02 change record](changes/2026-10-02-svg-icons.md). Offscreen testing does not establish native Wayland interaction behavior. SVGs are reusable assets; existing Canvas controls have not been migrated.
