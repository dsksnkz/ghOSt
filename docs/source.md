# Source and installation

All code needed by the current ghOSt rail/sidebar/calendar/Settings is published in this repository. The installer copies the complete `config/quickshell/ghost-bar/` tree, including JavaScript, Python, icons, artwork, fonts and `qmldir`; it does not depend on ignored development files or the previous rice's shell. Generated caches/logs and private local preferences/screenshots are not distributed.

## Layout

- `shell.qml`: native windows, shared focus/dismissal and public IPC entry points.
- `Rail.qml`, `Workspaces.qml`, `WorkspaceWheel.js`: rail controls and workspace projection/input.
- `Sidebar.qml`, `SidebarFigmaBody.qml`: native sidebar window, grouped controls and dismissal.
- `CalendarWindow.qml`, `CalendarPanel.qml`, `LiquidMeter.qml`, `WeatherGlyph.qml`: complete calendar, instrumentation and motion.
- `SettingsWindow.qml`, `SettingsPanel.qml`, `Settings.qml`, `settings_backend.py`: native Settings, navigation, validated actions and persistence.
- `Notifications.qml`, `notifications.py`: standard-protocol notifications with occupied-owner preservation.
- `Theme.qml`, `G2Surface.qml`, `G2Image.qml`, `Corners.js`: shared geometry/material/font rules.
- `install.sh`, `scripts/install.py`: explicit stage/activation and original-preserving recovery.
- `tests/`, `scripts/verify_*.py`: backend/distribution tests and isolated actual-QML verification.
- `site/`: GitHub Pages screenshots and preview. It is not the desktop runtime.

QML source is expanded with the installed Qt6 formatter instead of compressed one-line controls. Geometry changes use named sizing rules; current row/icon/gap/calendarscale values are inspected at runtime by `verify_spacing.py`. Python backends keep validation and standard system calls separate from the visual layer. Source formatting is not a substitute for behavior tests.

## Checks

```sh
python3 -m unittest discover -s tests -v
node tests/test_launcher.cjs
node tests/test_workspace_wheel.cjs
node tests/test_corners.js
git diff --check
```

`test_distribution.py` performs a fresh installation in temporary XDG directories and byte-compares all source/assets without starting ghOSt or editing live config. `python3 scripts/verify_input.py` uses the installed QtTest module inside a separate offscreen Quickshell entry to send actual Qt Escape/pointer events to the same sidebar/dismissal widgets. This is a widget event test, not a claim of physical compositor input automation. Run native/fixture checks from the change record, never session/power actions to test.

Requirements: Arch/Hyprland, Quickshell with networking/Bluetooth/PipeWire services, Python3/GObject-Gio and JetBrainsMono Nerd Font Mono. Plain JetBrains Mono/Turret Road fonts are included. GPU instrumentation uses available system telemetry. Optional tools/services expose honest unavailable states. Weather reads the user's explicit `$XDG_CONFIG_HOME/ghost/weather.json`; installation does not infer a location or overwrite preferences. The existing approved London configuration is unchanged on the owner's laptop.

Fresh installation defaults to an isolated stage. `./install.sh --activate` deliberately installs/starts ghOSt and adds only its own integration. It does not silently disable another bar or replace existing shortcuts. The complete independent lock/EQ/terminal/migration backlog remains documented; shipping the current source does not claim those functions finished.
