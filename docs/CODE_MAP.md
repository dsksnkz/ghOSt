# Editing ghOSt

The editable shell source is in `config/quickshell/ghost-bar/`. Installed copies
under `~/.config/quickshell/ghost-bar/` are deployment output; make durable edits
in the repository, verify them, then copy only the affected files.

## Main responsibilities

| Area | Files | Responsibility |
| --- | --- | --- |
| Entry and routing | `shell.qml`, `Desk.qml`, `Panel.qml`, `PanelContent.qml` | Native windows, shared desktop state, panel placement and page routing |
| Launcher | `Launcher.qml`, `LauncherSearch.js` | UI/input/scrolling; separately testable catalogue ranking and command arguments |
| Popup entrance | `Panel.qml`, `PanelContent.qml`, `PanelMotion.js` | Native launcher slides at full size below the rail; other popup transforms remain separate |
| Settings navigation | `SettingsNavigation.js` | Stable page IDs, names, icons, grouping and pure layout calculations |
| Settings pages | `SettingsPanel.qml`, `Settings.qml`, `settings_backend.py` | Page controls, bounded state refresh, and explicit system actions |
| Wallpaper browsing | `WallpaperPicker.qml` | Dark image/folder browser, bounded thumbnails and selection preview; only confirmation emits an apply request |
| Top-bar customization | `TopBarEditor.qml`, `RailLayout.js` | Real rail preview, drag regions, hidden tray and pure ordering/placement; `settings_backend.py` validates and saves the full layout |
| Calendar/sidebar/rail | `CalendarPanel.qml`, `CalendarWindow.qml`, `SidebarFigmaBody.qml`, `Rail.qml` | Their corresponding surfaces; shared icons and corner components stay separate |
| Lock | `lock.qml`, `lock/` | Session lock/authentication ownership separated from visual scene components |

In `Launcher.qml`, row geometry and motion values are named once near the top.
`move()` selects a row; `scrollTargetForIndex()` computes the viewport target;
`resetSelection()` handles reset behavior; process dispatch stays in `launch()`.
Do not change animation timing as a substitute for optimizing computation.

In Settings, preserve both category order and navigation group order: they are
intentionally not identical. `SettingsNavigation.js` does not query services,
change settings, or mutate category objects when calculating row positions.

## Verify without touching the desktop

Run from the repository root:

```sh
node tests/test_launcher.cjs
node tests/test_settings_navigation.cjs
QT_QUICK_BACKEND=software python3 scripts/verify_launcher_commands.py
QT_QUICK_BACKEND=software python3 scripts/verify_input.py
QT_QUICK_BACKEND=software python3 scripts/verify_surface_compile.py
python3 scripts/verify_wallpaper_picker.py
node tests/test_rail_layout.cjs
python3 scripts/verify_rail_layout.py
python3 scripts/verify_launcher_motion.py
```

The launcher verification uses preview mode: it does not execute typed commands
or launch applications. Pure Node tests cover logic; Qt tests cover actual input,
selection animation, geometry and integration. Neither alone replaces native
visual verification where a rendering/backend change is involved.

## Generated and private files

`shaders/liquid.frag.qsb` is generated from `shaders/liquid.frag` using
`scripts/build-shaders.sh`. Edit the `.frag` source, not the compiled package.
SVG artwork is editable text. Recordings, fonts, audio and raster images are
assets rather than application source.

Do not commit local preferences, nearby Wi-Fi names, notification history,
private media titles, or the recovery snapshots under `.local/backups/`.
