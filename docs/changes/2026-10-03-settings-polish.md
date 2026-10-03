# 2026-10-03 · Settings and rail polish

Source instructions: `prompts.md` blob `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`; mainDesigns calendar image blob `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`. Local copies match GitHub. Newer direct corrections and the [current Figma](https://www.figma.com/design/mImDMio3PmIliY2Xyk3ODO/hyprland-rice-design) take precedence. This prompt revision remains pending for the gaps below.

## Output

- `SettingsPanel.qml`, `SettingsWindow.qml`, `Settings.qml`, `SettingsToggle.qml`, `SettingsSlider.qml`, `settings_backend.py`: independent fourteen-page Settings, measured frame/navigation, searched categories, native PipeWire inputs/outputs, explicit actions and local opt-in history.
- `G2Surface.qml`, `Material.qml`, `Key.qml`, `FadeLabel.qml`: continuous corners, grayscale material, color-only hover, press feedback and right-edge fades.
- `CalendarPanel.qml`, `CalendarWindow.qml`: 10% wider whole composition, unchanged height/type, real liquid instrumentation and weather animation. Gear opens the new Settings window rather than an empty route.
- `SidebarFigmaBody.qml`, `Sidebar.qml`: three-layer cards, larger right-anchored status, random whole-group entrances, proper clipped list rendering and the separate Settings app.
- `Bar.qml`, `RailReservation.qml`, `Rail.qml`, `Workspaces.qml`, `workspace_scroll.py`: transparent outer surface, stable workspace indicator, soft power glow and a separately measured work-area reservation.
- `config/hypr/hyprland.lua`, `capture.py`: staged standard-service command mappings and independent region capture. No global shortcut remapping was activated in this pass.
- `site/`: Settings pages and updated actual-QML captures, using a separate export of the current laptop wallpaper. The original wallpaper is unchanged.

Screenshots: [Settings](../../site/assets/settings-general.webp), [sound](../../site/assets/settings-sound.webp), [battery](../../site/assets/settings-battery.webp), [widgets](../../site/assets/settings-widgets.webp), [brightness](../../site/assets/settings-brightness.webp), [wallpaper](../../site/assets/settings-wallpaper.webp), [notifications](../../site/assets/settings-notifications.webp), [composition](../../site/assets/desktop-frame.webp), [calendar](../../site/assets/calendar-frame.webp), [sidebar](../../site/assets/sidebar-frame.webp), [long names](../../site/assets/sidebar-long-names.webp), [rail](../../site/assets/rail-frame.webp). All Settings categories are accessible in the [Pages preview](https://dsksnkz.github.io/ghOSt/). Captures explicitly use sample data; they are not a remote desktop feed.

## Native rail transition

The user's final direct request authorized replacing the previous rail's autostart with ghOSt. Added exactly one ghOSt startup command to the existing Hyprland start handler. A reversible `bar.enabled` guard disables only the previous rail and its reservation, retaining unrelated wallpaper, authentication and shortcut services. This is local migration compatibility, not a ghOSt runtime dependency. Neither the old rice nor its backups were uninstalled.

Live ghOSt namespace is `ghost-bar`, 1920 × 64 at (0,0). The transparent input-empty reservation is mapped and Hyprland reports `[0,64,0,0]`, so windows begin below the rail. No old rail layer remains. Native calendar is 806 × 310 below the rail; sidebar is 356 × 794. Settings is a centered 1024 × 699 floating window using a title/class-specific rule; no unrelated window rule changed. Quickshell cold load and reload succeeded without ghOSt QML warnings. A stale sidebar alias was found by native loading and repaired before handoff.

Keybind file SHA-256 is unchanged: `c0ade5d4f7a9706be56bf3a0a4257058bf1255e1dcb4ce47f71a109b8844b261`. Bind JSON SHA-256 is unchanged: `ec0f696afa82d444033071247e554ef4675897d570b5954c4eb9cdea5f45b2b5`. Hyprland configuration errors are empty. Persistence is verified from startup files, not through a reboot/login test.

Snapshots: `.local/backups/2026-10-03-resume/` for source; `.local/backups/2026-10-03-rail-transition/` for exact affected installed paths. The latter holds `autostart.lua`, `keybinds.lua`, `legacy-Bar.qml`, `legacy-settings.json`, `launcher` and the previous `ghost-bar/` profile. Private native captures stay under `.local/verification/` and are not published. The existing installer manifest predates this transition; do not use its old restore blindly.

To undo this transition, preserve any subsequent edits first, restore the saved autostart, old bar source and only the saved `bar.enabled` value to their original paths. Do not overwrite the entire legacy settings JSON if it has newer preferences. Restore the saved ghOSt profile separately, reload Hyprland and the named shells, or deliberately stop only ghOSt. Keybindings were not changed and do not need restoration. Recovery does not require deleting any rice.

## Verification and remaining work

36 Python tests and 15 launcher assertions pass. Isolated QML checks cover fourteen Settings pages/geometry, empty search, Settings navigation, randomized grouped sidebar entrances, long-name rendering and clean captures. Calendar checks cover ratio, random 1.5-second reveal, animated rain/lightning, reduced motion and closed-state suspension. Icon tests include XML/tone/transparency parity. Default staging installer, JavaScript syntax and whitespace checks pass.

Native Settings and the running rail/calendar/sidebar were visually inspected; live status reads hardware/services. No volume, microphone, network, backlight or wallpaper setting was changed to test a setter. No power/session action ran. Preview power actions are explicitly disabled.

Remaining: exact Figma portrait asset and unmeasured layers; embedded equalizer bands (currently opens the existing EasyEffects editor); independent lock and notification daemon/history; external-display brightness; unavailable awww wallpaper daemon; native physical pointer/keyboard automation and multi-monitor testing. Widget visibility currently retains the measured layout's spacing. The staged source has no legacy imports, commands or symlinks, but preserved live legacy shortcut/service handlers mean the whole desktop session is not yet independent.

Rule reference: [Hyprland window rules](https://wiki.hypr.land/configuring/core/rules/window-rules/). Publication status is recorded in `docs/PROGRESS.md` after deployment.
