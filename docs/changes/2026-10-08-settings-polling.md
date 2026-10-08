# Settings background work

Every Settings page previously launched the complete Python status helper every
five seconds while visible, including brightness, disk-space and history reads
when the user was viewing General or a live-service page.

The actual content page now selects the refresh interval. Battery, Brightness
and Storage retain five seconds; the other eleven pages use sixty seconds.
Startup and opening still fetch preferences/state, page changes request a fresh
read, and explicit actions still return updated state. Existing running-query
and action guards remain intact. Closing Settings stops periodic queries.

In a steady visible static page this schedules one periodic helper launch per
minute instead of twelve; startup, page changes and user actions add their own
requests. This is a reduction in scheduled backend work, not a measured FPS,
battery-life or whole-desktop speedup. Externally edited ghOSt preferences on a
static page can now take up to sixty seconds to appear; reopening refreshes them.
PipeWire audio, Wi-Fi, Bluetooth and notification service updates remain live.
Opt-in minute usage-history sampling is unchanged and remains off by default.

`SettingsWindow.qml` binds the singleton's page to its actual content, not the
last requested page. `Settings.qml` owns the interval and privacy-safe query
counters. No new IPC method is needed: existing `bar.settingsFlow polling`
returns only page/timer/query metadata. [Qt Timer](https://doc.qt.io/qt-6/qml-qtqml-timer.html)
resets elapsed time when its interval changes; the page-change refresh avoids
waiting for the new period before loading current values.

## Verification

- `python3 scripts/verify_settings_polling.py` runs the actual Settings singleton
  with a windowless Qt root and inert test backend. All 14 page intervals checked;
  startup/open/page refresh verified; General does not query at five seconds;
  Storage's real five-second timer queries; hidden Settings stops querying;
  fixture mode suppresses startup/open/periodic backend calls. No real system
  service, setter or visual preview runs in this test.
- All 61 Python tests and existing network policy, wheel, launcher, corner and
  cached-wave JS regressions pass.
- Native General: query count remained 2 beyond the old five-second interval.
  Native Storage: opening refreshed it, then queries increased 3 to 6 during
  inspection with interval 5000. Closing disables the timer. This checks native
  page binding and query scheduling, not automated physical navigation input.
- [Actual native Storage](../images/2026-10-08-settings-polling/storage-native.png)
  retains the existing material, type, spacing and current disk usage. Capture
  excludes portraits, PC names, private filenames, network names and chats.
- Both runtime files were copied byte-identically into the active ghOSt profile.
  Hot reload succeeded without a restart: ghOSt PID 222465 and legacy PID 1824
  unchanged. Settings remains 1024×699 at (448,216); native logs are clean.
  Closed-panel state restored after inspection; query count stays 6 while hidden.
  Rail reservation remains 50px, compositor errors are empty, notifications remain
  in observation mode and Ethernet/Wi-Fi remain connected. Live binding SHA-256
  remains `3933ec4838952df5fb833b523d64ef9eeb56ee823c043d695d9447e6930fbc05`.

No shortcut, wallpaper, autostart, radio, audio or system preference changed.
No editable Figma tab was available; the supplied design image was read and no
visual redesign or parity claim made. Current remote/local source blobs match:
`prompts.md` `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`, design image
`9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`, and `mainDesigns/1`
`8b137891791fe96927ad78e64b0aad7bded08bdc`. No preview-site layout changed.
Broader reference, embedded equalizer, independent lock and migration work remain
pending.

Published source release `5de3fd4` to GitHub `main`. Its fresh committed archive
passes all 61 Python tests, the actual Settings timer/process test (including
fixture suppression), and existing JS regressions. Remote Git blobs match the
new Settings singleton and privacy-safe native Storage screenshot. Native panels
remain closed and neither shell was restarted.

## Recovery

Snapshot `.local/backups/2026-10-08-settings-polling-zuvnrE/` holds the affected
source, documentation and exact live originals. Restore its two `live/` files
into the existing ghOSt profile to return to the previous polling behavior; native
hot reload applies them. No unrelated rice or service needs changing.
