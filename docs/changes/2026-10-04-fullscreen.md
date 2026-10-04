# 2026-10-04 · Rail fullscreen visibility

`Bar.qml` unmaps the rail while its own monitor's active workspace has a fullscreen window. `FullscreenState.qml` follows Hyprland workspace signals without polling. Leaving fullscreen or choosing a normal workspace restores the rail. Normal overlay stacking is retained so another shell cannot intercept the controls. Work-area reservation, shortcuts and autostart are unchanged. `qmldir` includes the new component for complete installation.

## Verification

48 Python tests pass. The actual Qt input entry verifies fullscreen entry/exit, workspace changes and missing-monitor fallback, alongside Escape/outside dismissal. Native ghOSt hot-reloaded with clean logs and normal rail mapping; the user confirmed fullscreen works. No existing game was toggled by the agent. Compositor fullscreen transitions are user-confirmed, not automated physical input.

Spacing, sidebar entrance and weather/calendar checks rerun serially and pass. The previous six corrections are already deployed/published: rounded Settings selection, optical clock/calendar/battery alignment, real notification popup, empty notification center, Escape/outside sidebar dismissal and grey calendar border. Broader unfinished requests remain pending. An inadvertently native preview launch was immediately closed, then checks used the isolated offscreen entry; no session action executed.

## Output and recovery

[Native rail](../../site/assets/rail-native.png) · [Settings](../../site/assets/settings-general.webp) · [Sidebar](../../site/assets/sidebar-frame.webp) · [Notification popup](../../site/assets/notification-popup.webp) · [Calendar](../../site/assets/calendar-frame.webp) · [Pages](https://dsksnkz.github.io/ghOSt/).

The native1920×64 crop excludes application/private network content. Preview describes fullscreen behavior and links this output. The separately exported current wallpaper remains unchanged. Snapshots: `.local/backups/2026-10-04-fullscreen-tS3xCJ/`; restore its live `Bar.qml`/`qmldir` to reverse this change. Added unused helper can remain. Only ghOSt updated; unrelated processes preserved.

After an initial network-route failure, upstream hashes were successfully rechecked: prompt `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`, design tree `d0aa22ca90f6dad13493bdc6325d0c43847af98c` and image `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`, matching local files. User text untouched; full prompt is not marked complete.

## Publication

Source `72b60e213421807ab9e7cfe3745247d58bb4f6c1` pushed. [Pages deployment37208796866](https://github.com/dsksnkz/ghOSt/actions/runs/37208796866) succeeded. Published HTML, script and actual native rail screenshot are byte-identical to local files. A fresh tracked archive installs the new component and passes all48 Python tests plus actual Qt dismissal/fullscreen assertions. Owned previews closed; native ghOSt remains running with clean logs and unchanged shortcut/autostart hashes.
