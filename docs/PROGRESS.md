# ghOSt progress

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
