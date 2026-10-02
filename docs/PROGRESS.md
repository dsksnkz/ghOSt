# ghOSt progress

## 2026-10-03 / reference-matched frame refinement in progress

The 2026-10-03 annotated screenshots establish the intended composition. The tested live rail and calendar now use 7 px outer radii; the calendar is 733 × 308 px on the 1920 × 1080 monitor, directly below the 46 px rail. The calendar font sizes were corrected after inspecting a native crop. Its weather comes from the user-selected London location, real CPU/GPU/RAM/processor readings drive the liquid meters, and the storm/rain motion was exercised in an isolated fixture. The workspace control is a three-position wheel. Rail controls use ghOSt SVG icons; the compact power HUD opens without invoking any power action and requires a second confirmation click for disruptive commands. Lock is explicitly unavailable until an independent ghOSt lock configuration exists.

An independently authored left sidebar is staged with 7 px outer radius and nested radius computed as `max(0, outerRadius - padding)`. It contains Wi-Fi/Bluetooth lists, volume, brightness status and a notifications status area. It was inspected on the live desktop during development but removed from the live shell because the user's earlier activation approval covered only calendar and rail; separate approval was requested for sidebar activation. The installed rail therefore retains its preexisting network/Bluetooth/battery panels until approval. Sidebar brightness remains unavailable on the current HDMI display (no usable DDC display), and a notifications service was unavailable; neither value is fabricated. Settings is currently a small functional control overlay, not a complete Settings app.

Verification: GitHub `prompts.md` and `mainDesigns/Screenshot 2026-09-30 212732.png` matched local blob hashes `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d` and `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`. Fifteen Python tests and fifteen launcher assertions passed. Isolated QML preview loaded; IPC verified random reveal ordering, 1.5 s completion, rain motion, periodic storm lightning, reduced motion and stopping animation when closed. Native Quickshell reloads reported `Configuration Loaded`; `hyprctl configerrors` was empty and the live bind JSON SHA-256 was unchanged (`b2b4875462ecbc112533f0a6c6101116d715b1870ed98cf4c95b37c931de0651`). Native panel layers and cropped screenshots were checked. Physical mouse clicks on the Wayland rail and all sidebar list actions were not independently automated.

Local evidence: `.local/verification/calendar-refinement/calendar-native-final-crop.png`, `calendar-final-preview.png`, `sidebar-final-preview.png`, `power-final-preview.png`, `rail-final-preview.png`, `site-desktop.png`, `site-mobile.png`, and `power-native.png`. The older `sidebar-7px-live.png` contains real nearby SSIDs and must never be published. Public-ready sample-data renders are `site/assets/{calendar,sidebar,power,rail}-frame.webp`. Snapshot: `.local/backups/calendar-refinement/`. The previous entry below describes the earlier staging point and is superseded where activation or weather status differs.

Remaining before full prompt delivery: obtain sidebar activation answer; finish the old-rice dependency audit (the untouched staged `config/hypr/hyprland.lua` still has references, and some older components may too); build an independent lock entry and notification surface; verify direct Wayland pointer interaction and site publication. The installer no longer rewrites another rice's shell. Do not mark `prompts.md` complete yet. The next scheduled run should continue this work, without usage-threshold deferral.

## 2026-10-02 / calendar frame local staging

Continued the existing unfinished implementation of the user's full mainDesigns frame: weather left, GPU/RAM/CPU liquid diamonds centrally (CPU switches to clock), calendar right, bottom controls and the visible rail clock/date/weather group. Added flat panel material, reduced-motion reveal handling, inner-panel Escape handling and functional launcher navigation. Rail tooltip text remains disabled with accessible names retained. Frame drop uses 220ms; six subframes reveal in randomized order over 1.5 seconds. Waves and sampling stop when closed.

Verified local prompt/design blobs against GitHub: f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d / 9cc34c7e555a0cbfbff777d194a13ac3b799e6fe. Fifteen Python tests and fifteen launcher assertions pass. Isolated QML loads without component errors; month navigation, randomized reveal order, reduced motion, clock switching and close state checked through preview IPC. Screenshots: .local/verification/calendar-evening/calendar-full-frame.png (explicit sample data) and calendar-real-readings.png (live metrics). Snapshot: .local/backups/calendar-20261002-evening/; final-pass component snapshot also retained.

No active configuration changed or activation performed. Weather needs a user-selected location; no live forecast validation claimed. Power actions are deliberately unavailable in staging; Settings contains reduced-motion and location guidance, not a complete settings application. Native pointer/keyboard behavior and frame timing on Wayland still need isolated interactive verification. No publication this pass. hyprland.lua work was stopped at the user's request and its earlier staged file remains untouched.

## 2026-10-02 / 0.3.1 assets staged

Published 60 standalone SVG icons in black and white, a QML wrapper and isolated catalogue, and a searchable responsive download gallery. Nine Python tests (including 240 raster checks), 15 launcher assertions, and all 120 QML icon images passed. No live desktop activation. See [change record](changes/2026-10-02-svg-icons.md).

Remaining: supplied calendar composition/motion, rail tooltip removal, terminal reference matching, compact power HUD, and complete removal of old-rice runtime dependencies. prompts.md remains pending, not completed. Usage at start 0% five-hour / 16% weekly; publication preparation 52% / 24%. No reset credit used.

## 2026-09-30 / 0.3.0 staged

Added the independent launcher: ranked native application search, bounded keyboard selection, persistent pins, empty results, and six new monochrome icons. The G control and session launcher action now target this component in staged source. No shortcut changed. Actual component renders and Pages cover launcher, search, empty results and the expanded icon pack.

Checks: 15 launcher assertions, six telemetry tests, isolated QML load, 112 desktop entries, pin persistence after restart, selection boundaries, preview-safe launch dispatch, staging installer, unchanged live bind JSON and native PIDs. Desktop and 390px web layouts reviewed. Native keyboard events and actual app startup remain untested; the installed older bar is unchanged.

Usage at start: 0% five-hour / 50% weekly; verification milestone: 35% / 56%. No resets used. Keep remaining runs bounded by the account-wide daily/weekly guard.

Backup: `.local/backups/20260930-launcher/`. Evidence: [launcher change record](changes/2026-09-30-launcher.md). Next: opt-in native integration validation; then an independent settings surface. Do not activate unattended.

## 2026-09-29 / 0.2.1 staged

Repaired the previous run before extending the surface set:

1. Replaced load-average-derived pseudo-percent and hardcoded GPU/clock zeros with real selected-metric telemetry.
2. Replaced Canvas font strings with Qt labels; added explicit unavailable/stale states, hardware frequency scale and a larger 60-tick dial.
3. Added the actual bundled Turret Road G; repaired overlapping network layout, neutralized material RGB values, added keyboard focus and removed workspace hover fills.
4. Anchored panel morphing to the clicked control; extracted Rail and PanelContent for isolated rendering.
5. Changed the installer default to staging. Activation requires --activate.
6. Replaced published fullscreen chat captures with clean actual-component renders and an interactive preview gallery.

Active PIDs 1850 (Serpantinum) and 46390 (installed older ghost-bar) were preserved. This run does not deploy new files into live configuration. Live keybind JSON was identical before/after. The sibling project contract currently requires a separate opt-in rice.

Known gaps: native validation of the new motion/focus; full independent launcher/settings/theme coverage; portable GPU selection beyond the first supported device. Current native ghost-bar is still the older version with its telemetry/font defects.

Publication correction: latest tree and Pages images are clean. The earlier chat captures remain recoverable in Git history. History rewriting is not performed unattended.

Evidence and screenshots: [change record](changes/2026-09-29-telemetry-repair.md).
