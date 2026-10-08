# Native interaction pass

The [direct request](../requests/2026-10-08-interactions.md) authorizes creative
music/OSD additions and replacing only the legacy OSD and edge triggers. Eleven
requested changes are implemented and live. Nautilus is untouched, pending the
requested follow-up question. This does not complete the broader design backlog.

## Changes

- Music: seven animated playback-indicator bars, previous/play/pause/next SVG
  controls, real MPRIS progress, and an expanded player with artist, elapsed/total
  time, seek and stop. Capability guards disable unsupported operations. The
  bars are motion, not an audio spectrum. Timers/animation stop when inactive or
  hidden; reduced motion is respected. Seeking uses actual seconds and accounts
  for the larger pointer target. Media uses transparent outside dismissal rather
  than a keyboard grab. The user clarified they clicked during capture: those
  disappearing captures are not evidence of spontaneous closure or a fixed bug.
- WLAN: removed the scaled offscreen list texture that softened text. Disconnected
  networks have Wi-Fi glyphs; the connected network retains its check. Bluetooth
  list texture was removed too. Scan demand remains visibility-controlled.
- OSD: independent left-side volume/backlight panel, 280ms scale/rightward
  entrance, percentage and vertical Qt Slider with touch drag support. Volume
  follows real PipeWire changes. Brightness reads the standard backlight interface
  on request and uses debounced writes; no continuous brightness subprocess poll.
  The 2.2s expiry waits during dragging. No fake hardware values.
- Weather: hollow `>` at the selected row. Wheel or row selection changes the
  headline glyph, condition and temperature together. Today retains the real
  current observation; historical/forecast rows retain real dated values. This
  explicitly supersedes the earlier always-current headline policy.
- Settings: one continuous-corner selection surface moves between row coordinates
  over 280ms with cubic Bézier easing. Most Key controls now pass wheel events to
  their enclosing Flickable; workspace/volume wheel targets opt in. The nav list
  is 824px tall and actually scrolls. Existing grouped frames remain intact.
- Left edge: one narrow ghOSt hit strip grows into a rounded ghost-icon handle
  on hover; click opens Sidebar. No right/top/bottom ghOSt edge handles.
- Shortcuts: Super+I opens General. Existing volume/mute/brightness key combinations
  retain their repeat/locked flags, but call standard services and the ghOSt OSD,
  not legacy OSD helpers. Unrelated shortcuts, wallpaper and autostart stay intact.
- Click sounds: three distinct deterministic original PCM pops, reused per
  rail/sidebar/Settings; 40–55ms, low amplitude and 18% playback volume. No random
  sound choice. Effects preload once, with a 45ms rapid-click guard. Fixture tests
  are silent. Keyboard activation uses the same button signal.
- Outside dismissal: a transparent native input surface covers the desktop while
  Sidebar or Calendar is open, with holes for the active card and rail. Blank rail
  presses close panels; other rail actions close or replace them. Unrelated
  notification/panel holes no longer leave undismissable areas. The first outside
  click is consumed, not forwarded into the underlying application.
- Date calendar only: grid scale 1.06 plus larger month/day/date/footer type,
  repositioned within the unchanged Calendar frame. Weather/meters keep their
  space. Main panel, sidebar scale, radii and rail dimensions were not redesigned.

The earlier [Settings page router](2026-10-08-settings-routing.md) is included in
this release; its pending safe-capture checkpoint is resolved.

## Verification

62 Python tests pass, including complete isolated installation and sound format,
duration/amplitude/distinctness. Actual Qt event tests cover Escape, outside
pointer dismissal, fixed click-sound/action dispatch, fullscreen restoration,
nav wheel propagation, intermediate
and settled selector positions, weather headline agreement and music geometry.
Production surface compilation creates no windows or backend actions. Settings
router (10 transitions), polling (14 pages and real five-second timer), network
binding (12 transitions), plus network policy (128), workspace wheel, launcher
(15), continuous corners and cached waves (24,300 vertices) pass. Five website
regressions also pass; no website redesign was made.

Native installation is `/home/matte/.config/quickshell/ghost-bar`. Exact source
files match installed runtime files. ghOSt PID 222465 and legacy PID 1824 were
retained through hot reload. Rail remains 50px tall. Hyprland configuration errors
are empty. Notifications retain their existing owner and observation mode.
SoundEffect status is Ready for all three assets. Native brightness 46% and volume
37% were read without setting either. The new OSD and left-edge layers map on the
left. Native expanded music maps 392×334 and shows real paused media/progress.
No playback, seek, volume, brightness, Wi-Fi connection or power action was run
by verification. Physical touch, physical media controls and compositor pointer
hit-testing were not automated; standard Qt input tests are not proof of those
hardware/compositor paths.

Native crops were visually inspected before publication:

- [rail and compact music](../images/2026-10-08-interactions/rail-native.png)
- [Settings navigation](../images/2026-10-08-interactions/settings-navigation-native.png)
- [selected forecast and enlarged date grid](../images/2026-10-08-interactions/calendar-native.png)
- [OSD interior](../images/2026-10-08-interactions/osd-native.png)
- [sidebar header](../images/2026-10-08-interactions/sidebar-header-native.png)
- [WLAN icon column](../images/2026-10-08-interactions/wlan-icons-native.png)
- [real media progress, excluding private title](../images/2026-10-08-interactions/music-controls-native.png)

Full WLAN captures, media titles and interrupted background-app captures stay
under ignored `.local/verification/`, never in public assets. The initial OSD
opened-binding loop was repaired; no new UI binding warnings followed the latest
reload. Departed MPRIS/output warnings and a malformed installed desktop-entry
warning are unrelated and not claimed repaired here.

Prompt/design blob hashes still match the default branch:
`f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`,
`9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`,
`8b137891791fe96927ad78e64b0aad7bded08bdc`.
No new editable Figma property evidence or 100% parity claim is made.

## Installation and local migration

Normal `install.sh` includes every new component and WAV in its existing safe
profile installation. Qt Multimedia is required for these click sounds; a
writable standard backlight and `brightnessctl` are needed for brightness.
No package was installed. [Optional owned key mappings](../../config/hypr/ghost-controls.lua)
are for the Lua configuration API: replace matching old mappings, do not append
duplicates. They are not silently installed.

This laptop's explicitly requested legacy migration is narrow: `general.quickactions`
is false in its private legacy settings, and the old OSD window's visibility is
false. Legacy notifications, wallpaper, screenshot/lock services and its process
remain. No legacy source/helper is imported into ghOSt. These personal settings
and legacy source are not distributed or exposed in this repository.

## Recovery and release

Snapshot `.local/backups/2026-10-08-twelve-changes-GXKI2J/` retains the exact
project/runtime originals, live keybinds and the two affected legacy files.
Restore only those paths after reconciling later user edits; restoring
`live/legacy-Osd.qml` and `live/serpantinum-settings.json` re-enables their prior
surfaces. Reload Hyprland only after restoring its keybind file. No broad process
stop, hardware change or session restart is necessary.

Published runtime/crops in `41d2f3a`. A fresh committed archive passed all 62
Python tests, Qt input/compile/router/polling/network checks and JS checks listed
above. Remote runtime, sounds, optional Lua controls and native crop blob hashes
match the commit. An additional silent Qt click probe confirms both the base SFX
handler and derived button action run once. Independent lock, embedded equalizer,
exact-reference backlog and the user's Nautilus choice remain separate.
