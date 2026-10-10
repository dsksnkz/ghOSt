# ghOSt progress

## 2026-10-10 / Restore Super+A to Zed

Restored the user-owned Super+A shortcut to installed `/usr/bin/zeditor`, both
live and in optional migration config. The earlier Widgets reassignment was
incorrect and superseded; Super+I remains Settings. Only this binding changed.
Lua syntax and Hyprland config reload/configerrors verified without opening
Zed or any test window. Snapshot `.local/backups/2026-10-10-super-a-zed/`.


## 2026-10-10 / Explicit launcher Escape dismissal

Escape is consumed before TextField handling and emits launcher closeRequested,
connected to Desk.close in production (preview popup close in isolated tests).
Stops keyboard scroll and clears query/last request without running any command.
Offscreen real Escape from populated command input verifies one close request,
cleared input and no execution; launcher/input and compile checks pass. No
desktop-visible test window or app launch. No visual geometry change; existing
launcher-scroll screenshots remain applicable. Two live files deployed with
named ghOSt reload. Snapshot `.local/backups/2026-10-10-launcher-escape/`.


## 2026-10-10 / Smooth launcher viewport scrolling

Removed immediate positionViewAtIndex calls from arrow selection: viewport
contentY now animates over 220ms using the outline's same Bézier curve. Selection
outline uses stable index/row coordinates rather than virtualized item geometry.
Only the minimum scroll to fully contain the selected row is requested; rapid
keys retarget from the current frame, pointer scrolling interrupts the keyboard
animation, reduced motion remains instant, and fresh query/open resets scroll.
Real offscreen key-event tests verify a nonzero intermediate scroll (no snap),
outline/viewport synchronization at the fifth row, rapid Down and reverse Up
settlement. Existing reset/commands/ranking/input/compile checks pass. Actual
scrolled component render recorded in `docs/images/2026-10-10-launcher-scroll/`.
Single live Launcher file deployed and named ghOSt reloaded; snapshot:
`.local/backups/2026-10-10-launcher-scroll/`. No app/command executed in tests.


## 2026-10-10 / Wider, flatter launcher

Latest clarification: wider and flatter, not narrower. Launcher now 560×328
(previously 480×384), four 48px rows with 8px gaps, 44px search and 32px icons;
18px labels stay legible and more names fit without truncation. Four whole rows
and bottom breathing room remain. Grey outline animation, real arrow-key control,
background commands and fresh-open reset retained. Offscreen key/animation/row
geometry tests and production compile pass; inspected actual render published
in `docs/images/2026-10-10-launcher-wide-flat/`. Two live files installed and
named ghOSt reloaded. Backup `.local/backups/2026-10-10-launcher-wide-flat/`.


## 2026-10-10 / Compact four-row launcher and keyboard outline

Reduced total launcher from 600×412 to 480×384; search 48px, icons 40px,
labels 18px, rows 60px with 8px spacing. Four complete rows fit instead of three,
with at least 16px bottom breathing room; whole-row sizing prevents a clipped
fifth icon. Selection is transparent with a 1px grey stroke, 220ms Bézier
translation and no row hover fill. Explicit BeforeItem arrow handling in the
search plus launcher-level fallback keeps Up/Down controlling selection without
moving focus out of the input. Enter/background commands and fresh-open reset
are unchanged. Real Qt key-event tests verify selection index, intermediate
animation position, both directions, transparent fill, four-row capacity and
bottom space; Node/input/compile checks pass. Offscreen actual render inspected
in `docs/images/2026-10-10-launcher-compact/`. Two live files installed, named
ghOSt reload invoked; `.local/backups/2026-10-10-launcher-compact/` preserves
affected project/live paths. No applications/commands executed in verification.


## 2026-10-10 / Launcher reference layout and background commands

Latest screenshot supersedes the previous compact launcher. Centered 600×412
panel (bounded on smaller displays), flat #191919 frame with 22px continuous
corners, 60px rounded search field, 80px rows, 50px installed app icons and 22px
JetBrains Mono labels. Removed header/count/footer chrome. Pinning remains
available on hover rather than permanently filling each row. One transparent
selection outline moves between rows with a 220ms Bézier animation; reduced
motion updates instantly. Existing ranking, keyboard navigation and scrolling
remain. Reopening invokes beginSession, clearing query and last request.

`> command` now dispatches Bash detached, without Kitty or another terminal,
only on explicit Enter/click. Quotes/pipes remain a single command argument;
no command history is persisted. Offscreen Qt checks verify reset, application
restoration, command execution guard and intermediate/up/down outline motion;
Node argv/ranking tests and existing input/compile checks pass. No actual user
command or application executed in tests. Inspected actual component renders
with installed Spotify icon and harmless sample text published at
`docs/images/2026-10-10-launcher-reference/`. Four live files installed; named
ghOSt reload invoked. Snapshot `.local/backups/2026-10-10-launcher-reference/`.
Native background-command execution itself remains untested, deliberately.


## 2026-10-10 / Terminal commands in launcher

Type `> command` in the existing launcher to reveal an explicit Run in terminal
row; Enter or clicking that row launches `kitty --start-as=normal --hold -e
/bin/bash -lc command`. The complete command is one argv item, preserving
quoting, pipelines and shell syntax. Ordinary queries remain app searches;
an empty `>` cannot run anything. Command rows cannot be pinned and command text
is not persisted. Preview mode returns before any execution; tests use it only.
Node command/argv regression checks, offscreen Qt Enter/row/pin/search tests,
existing input tests and production compile pass. No user command or terminal
was actually launched during verification. Screenshot with harmless sample text
in `docs/images/2026-10-10-launcher-commands/`; live Launcher/JS installed and
named ghOSt reload invoked. Snapshot `.local/backups/2026-10-10-launcher-commands/`.


## 2026-10-10 / Serpantinum uninstall — active removal complete, root links pending

Direct user request explicitly authorizes removing the legacy shell/processes.
Removed its autostart command and all active legacy shortcuts; ghOSt survives
unchanged as the sole QuickShell instance. Layer inventory now contains only
ghOSt surfaces; the duplicate top rail is absent. The previously observed
legacy PIDs had already exited before targeted termination (no process matched
the original PIDs); repeated process/layer checks confirm none remain.
Moved installed source, settings, state, runtime and three cache directories,
plus unused nested old shell under the live ghOSt directory, into recoverable
`.local/backups/2026-10-10-serpantinum-removal/`. Private backup is not published.
No pacman package exists. Root-owned `/usr/local/bin/serpantinum` and
`/usr/local/bin/serpantinumd` are now dangling/inert symlinks; removing these
requires administrator authentication (`sudo -n` unavailable). Full uninstall
is pending that final administrative step, not claimed complete.

Existing combinations retained: M reloads ghOSt, Space launcher, R system Info,
B Wallpaper, N Network. H now Info and A Widgets: these are not exact replacements
for the old guide/autohide pages. Number/Shift+number use native Hyprland workspace
focus/move; scroll, lock, screenshot and clipboard bindings remain intact.
Published optional `config/hypr/ghost-migration.lua` and independent reload IPC.
Lua syntax, compositor configerrors (empty), compile, IPC reload, notification
server takeover of the vacant name, live-source parity and legacy reference
search pass. No lock/power/workspace/screenshot shortcut action invoked.
Privacy-safe actual rail crop in `docs/images/2026-10-10-serpantinum-removal/`.
Wallpaper/theme and unrelated services untouched; notifications report ready
server mode. Administrator cleanup: `sudo unlink /usr/local/bin/serpantinum`
and `sudo unlink /usr/local/bin/serpantinumd`, after confirming each is a symlink.


## 2026-10-09 / Flat calendar and lighter weather glyphs

Removed the CalendarWindow frame gradient; retained flat #151515 fill, grey
border and 7px outer corners. Added weather-only variants of the existing six
SVG shapes with 1.25px rather than 2px strokes; headline and forecast use these,
animated rain drops reduced from 1.8px to 1.2px. No brightness/settings/shared
icon geometry changed. Weather data, switching, motion and calendar layout
remain intact. Compile, Qt input/weather transitions, 16 weather tests and icon
variant/parity checks pass. Isolated offscreen actual-component render inspected
and saved to `docs/images/2026-10-09-calendar-flat/calendar.png`; sample data is
not a current-weather assertion. Live calendar files and six assets installed,
only the named ghOSt instance restarted (the previous instance did not log a
reload), unrelated processes/shortcuts untouched.
Snapshot `.local/backups/2026-10-09-calendar-flat/`.


## 2026-10-09 / 30-degree cursor tilt and stable blur cancellation

Cursor-driven slat tilt is now capped at ±30 degrees. It smoothly blends with
credential reveal instead of switching from zero to the cursor angle at the
last frame. Kept the password field in the credential layout throughout fade-out
(disabled immediately), avoiding the centered column/clock height and position
jump. Backdrop blur now uses full-size render targets so toggling the layer does
not change the 3D viewport/projection. This supersedes the earlier quarter-pixel
backdrop optimization; shared materials and reduced shadow/MSAA cost remain.
Offscreen tests cover ±30 limits, intermediate tilt blending, unchanged column
position/height during cancellation, input clearing, idle and mock auth; compile
passes. Software cancellation capture in `docs/images/2026-10-09-lock-tilt30/`.
No visible testing or lock/PAM invocation. Native scale appearance still requires
user confirmation. Snapshot `.local/backups/2026-10-09-lock-tilt30/`; only the
affected ghOSt LockScene deployed after checking no active lock instance.


## 2026-10-09 / Frosted lock field and subtle cursor tilt

Password field now has a transparent G2 border with a cropped, masked blur of
the blinds inside, without the previous opaque grey fill. Backdrop sampling
excludes the credential column (no recursive password/clock capture). Only a
170×26 texture is sampled for the 340×52 field. Blinds respond smoothly to cursor
position with a bounded ±3-degree slat tilt, in both 3D and software fallback;
tilt disables during credential blur and reduced motion and fades out during
authenticated opening. Background clicks and idle clearing remain unchanged.
Offscreen input/mock-auth tests, bounds/transparent-fill assertions and production
compile pass. Software fallback screenshots are in `docs/images/2026-10-09-lock-glass/`;
software rendering cannot validate GPU frosted blur or real 3D appearance. Those
remain native/user-verification gaps, not claimed visually verified. No visible
test window, actual lock, PAM or session action was invoked. Snapshot:
`.local/backups/2026-10-09-lock-glass/`. Installed four affected lock files after
confirming no running lock instance; unchanged shortcuts/authentication files.


## 2026-10-09 / Lock dismissal, idle reset and rendering cost

Background clicks no longer wake credentials or introduce blur. When awake,
outside clicks or Escape clear the field and restore sharp blinds. A 10-second
inactivity timer does the same; typing/tapping the password resets it, shared
activity resets timers across outputs, and pending authentication pauses it.
Session-lock and PAM success gating are unchanged. Reduced rendering cost:
half-width/height blur target (quarter pixels), shared slat material, medium
MSAA/shadow map instead of high/very-high, and disabled SSAO. Sharp slats remain
full resolution with curved geometry, texture, cords and cast shadows retained.
No measured native FPS claim: all tests were offscreen as explicitly requested.
Software visual/input/mock-auth and production compile checks pass; verified
outside click, first-key wake, clearing, idle interval/reset and busy pause.
Offscreen RHI loads types but yields blank 3D captures on this platform, so those
are not accepted as visual evidence. A proposed cached-frame optimization was
removed before deployment. Published captures are labelled software fallback.
Snapshot: `.local/backups/2026-10-09-lock-idle/`. No real lock, PAM or visible
test window launched; no running lock instance when installing affected files.
Native perceived lag and authenticated unlock still need user verification.


## 2026-10-09 / Realistic Venetian blinds

Replaced flat stripes with shared curved thin-sheet 3D slats: crowned faces,
rounded end profiles, closed edges, brushed metallic paint, directional lighting,
cast shadows, front/back suspension cords and ladder rungs, head and bottom rails.
The original descent, credential blur and authenticated rotating exit remain.
Detailed gradient/texture/cord fallback supports the software Qt renderer.
Installed the six affected lock files into the existing ghOSt profile, with no
running lock instance and no session-lock, PAM or power action invoked.
Snapshot: `.local/backups/2026-10-09-realistic-blinds-SaUciM/`.
Software input/mock-auth tests and production compile pass. A short native
Wayland test window (not a session lock) verified the real OpenGL 3D renderer,
opening propagation, masked input and mocked authentication outcomes; inspected
closed, credential and rotating actual-render images are under
`docs/images/2026-10-09-realistic-blinds/`. Offscreen Qt falls back to software;
it cannot validate 3D output. Real PAM/unlock handoff remains user-test pending.


## 2026-10-09 / Super+L standalone import fix

User launch logs showed the nested lock entry failing before locking:
`G2Surface is not a type`. Earlier compile tests used the bar root and missed
the standalone nested-root import boundary. Moved the production entry to
`ghost-bar/lock.qml` so owned shared components remain inside the config root,
and assigned explicit `ghost-lock` ShellId. All local/public launch routes updated.
Correct-root compile, visual/input/mock-auth checks, Lua and live parity pass;
compositor reloaded without errors. Real lock/unlock still not invoked in tests.
Original frames remain applicable; no visual change.

## 2026-10-09 / Venetian lock screen

Independent Quickshell Wayland session-lock entry now has descending shaded
blinds with Bézier timing, first-key transition to blurred blinds/sharp digital
clock and masked password, and post-PAM-success slat rotation over the actual
desktop. Uses existing `/etc/pam.d/hyprlock`; no PAM/authentication files changed.
Installed and bound to Super+L/power-key Lock; wlogout's Lock action and ghOSt's
confirmed Lock menu route use the same entry. Actual session not locked in tests.
Qt visual/input/mocked-PAM policy checks, production compile, existing input suite,
Lua syntax and source/live comparisons pass. Safe test-rendered screenshots
published; real PAM, secure compositor handoff, multi-monitor/hotplug and physical
unlock round trip remain unverified. [Details, frames and recovery](changes/2026-10-09-venetian-lock.md).

## 2026-10-09 / Weather switch blur and left alignment

Forecast wheel/click selection now blurs/fades the complete weather headline
out, switches condition/temperature at the blur peak, then sharpens it. Latest
selection wins during rapid scrolling; reduced motion updates instantly and
closed panels stop the effect. Forecast glyph/row containers share the headline's
left edge; the hollow arrow remains just outside. Actual Qt input/transition
tests and compile pass; native blur0.726 and settled output captured without
private desktop content. Deployed source/live match and reload loaded cleanly.
[Screenshots, behavior and recovery](changes/2026-10-09-weather-transition.md).

## 2026-10-09 / Remove top rail calendar icon

Removed the calendar glyph beside the rail clock at the user's direct request.
Clock/date/weather positions and the clickable calendar target remain. Removed
the obsolete icon-center diagnostic/assertion. Production compile and diff
checks pass, native hot reload succeeds and source/live Rail match.
[Native output and recovery](changes/2026-10-09-rail-calendar-icon.md).

## 2026-10-09 / Remove left rail dividers

Removed the two separators between menu, desktop switcher and music at the
user's direct request. Existing spacing, rail outline and right-side dividers
remain. Production compile and diff checks pass, native hot reload succeeds,
installed Rail matches source. [Native crop and recovery](changes/2026-10-09-left-dividers.md).

## 2026-10-09 / Rail music background

Fifteen real Cava bars span the compact music background behind the larger13px
title and existing transport keys. No separate left spectrum column; other rail
text/geometry and expanded media panel remain. Dedicated30fps mono raw stream,
bounded frame parsing, fullscreen/pause/reduced-motion stop and fixture isolation.
Qt input/compile checks pass; live Cava observed, native crop excludes the user's
title and source/live files verified. [Details and recovery](changes/2026-10-09-music-background.md).
Published `9abd448`; remote main and both runtime QML blob hashes verified.
The unrelated upstream weather-location clearing commit was retained. This
music request is delivered; broader migration remains pending independently.

## 2026-10-09 / Serpantinum removal: migration pending

User requests removal and replacement with wlogout, Hyprshot and Clipse.
Live region/full-output screenshot shortcuts now use installed Hyprshot;
Super+V opens installed Clipse in Kitty, with its text/image watchers started
and persisted in autostart. No clipboard history was cleared or published.
Lua syntax checks and compositor reload pass, config errors empty, original
shortcut combinations remain registered. No screenshot/lock/session action
executed in tests. Hyprshot has no built-in editor and swappy is not installed:
old edit variants currently capture the same region/output without an editor.
Snapshot: `.local/backups/2026-10-09-shell-migration-4s9J3a/`.
Removal is not complete or published: wlogout is a session menu whose existing
Lock action calls hyprlock; no independent hyprlock configuration was found in
standard local paths. Confirm actual locking behavior before replacing the
lock handler or deleting the still-needed legacy instance. Other legacy
shortcut handlers and autostart remain pending migration.

## 2026-10-09 / Click-sound settings

Sound now starts with click-sound volume/mute, separate rail/sidebar/Settings
choices, private WAV import and single-sound preview keys. Defaults preserve the
original three cues/18% gain; media volume is independent. Typed private
preferences and bounded PCM validation preserve originals and unrelated settings.
Tested/deployed by hot reload, both shell PIDs retained; Settings opened on Sound
at the user's explicit request.71 tests, Qt and JS suites pass; native output and
Ready states inspected. [Details, native image and recovery](changes/2026-10-09-sfx-settings.md).
Published `9490dea`; remote revision/seven runtime, test and native-image blobs
verified. Fresh committed archive passes71 tests, silent Qt input/compile and
generator checks. This request is delivered; broader prompt remains unfinished.

## 2026-10-09 / Settings with Taste Skill

Refined Settings and its own sidebar using Taste's audit/spacing/hierarchy/
contrast principles, adapted to native QML. Larger functional search, fixed
icon/text alignment, more row space, live General summaries, grouped sound and
other controls, legible read-only facts and passive storage meter. All14 pages,
original portraits, name flow, creator names, scroll and reduced-motion selector
remain. Tested and hot-reloaded on the laptop; both shell PIDs retained.64 tests,
Qt input/compile/router/polling/scan and JS checks pass. Six native screenshots
exclude private lists and battery history/time. [Evidence and recovery](changes/2026-10-09-settings-taste.md).
Published `3be085f`; remote revision and twelve runtime/test/native-image blobs
verified. Fresh committed archive passes64 tests, generator and Qt suites.
Broader prompt remains unfinished.

## 2026-10-09 / Rounded icon family and Settings header

All64 owned glyphs now use the corrected rounded inner/outer style, including
the legacy-compatible Icon entry point, brand, weather and stationary indicator.
Settings matches the new header reference: original48px portrait/radius11,
full-width search, gear, higher selections; latest follow-ups remove dividers,
add16px top spacing and6px row gaps, and disable selected-row hover feedback.
Right-page content/functions remain. Tested and hot-reloaded visibly on the
laptop; both shell PIDs preserved.64 Python tests, Qt input/compile/router/polling/
scan checks and JS suites pass. Native Settings/Calendar/rail output inspected.
[Files, evidence, remaining limits and recovery](changes/2026-10-09-icons-settings.md).
Published `dc20fdd`; remote revision, all shell/site icon blobs and six native
images verified. Fresh archive passes64 tests, generator and Qt input/compile.
Broader prompt is not marked complete.

Taste skill separately installed globally at the user's direct request. No
project dependency or theme was installed; supplied design authority remains.

## 2026-10-09 / Folder redo: inner radii

Removed the rejected layered SVG/PNG and its dedicated tests; the deleted design
is recoverable in Git history and `.local/backups/2026-10-09-folder-redo-IOeZVO/`.
Rebuilt `folder-rounded` as an even-odd filled silhouette with separately rounded
tab/body cavities, eliminating the sharp inner joins of the previous stroked
version. Preview now derives from the same canonical geometry, not a duplicate.
Original `folder` and Nautilus remain untouched. All 63 Python tests, generator
freshness and diff checks pass; rendered preview visually inspected, including
rounded negative-space corners. Published `ffabbe7`; remote main and all six
asset blob hashes verified, with layered assets absent from the remote tree.
This supersedes the earlier layered and rounded-asset entries below.

## 2026-10-09 / Layered folder refinement

The user's follow-up explicitly asks for depth and shading, superseding pure
black/white for this asset. Created `assets/folder-layered.svg` and a transparent
512px PNG: dark rear/tab, recessed inner lip, light tapered front, lower edge
thickness, subtle highlights and contact shadow. Existing flat pack remains
unchanged; no desktop/Nautilus theme activated. Raster bounds, neutrality,
transparency, gradient variation and brighter middle/darker top verified at
32/256px; enlarged output visually inspected. All 64 Python tests and flat-pack
generator checks pass. Published `6017a49`; remote revision and SVG/PNG blob
hashes verified. No theme activation.

## 2026-10-09 / Rounded folder asset

Created `folder-rounded`: one original outline with softer body/tab corners and
a front fold, exported as transparent black and white SVGs in the existing icon
system. Original folder icon and Nautilus remain unchanged. All 62 Python tests
and generator freshness checks pass, including transparent black/white raster
parity at 24/48px. Enlarged preview inspected. Published `ecf2799`; remote revision
and all four SVG copies match their Git blob hashes. This is an asset, not a
theme activation.

## 2026-10-09 / OSD and real outside-click fixes

Sidebar's exclusive layer mode redirected outside clicks back to it on this
Hyprland version. Changed to OnDemand plus managed focus. Actual native left,
right, middle and Escape tests pass, including inside-click preservation and
no click-through; Calendar/Media outside presses also pass. Native diagnostics
have safe automatic cleanup and a five-second guard expiry.

Removed the old OSD instance from its local manager and forced a verified legacy
hot reload without restarting its process. The previous hidden-source edit had
not reached the running legacy configuration. Removed the horizontal cap from
ghOSt's volume/brightness slider, tightened side padding and darkened the OSD
card/track per the follow-up; actual native output inspected. 62 Python
tests, Qt input and surface compilation pass. Both shell PIDs, shortcuts,
wallpaper, autostart and notification ownership preserved.
[Cause, native proof, images, migration and recovery](changes/2026-10-09-osd-dismissal.md).
Published `aea9b3e`; fresh committed-archive checks pass, remote changed runtime
and native-image blobs match, and installed files match source. The standing
user instruction is to publish every completed verified change. Broader design
backlog remains pending; Nautilus is untouched.

## 2026-10-08 / Native interaction pass

Implemented the latest eleven desktop requests: animated MPRIS controls, crisp
WLAN text/icons, independent touch-capable left OSD and edge handle, forecast
switcher, moving Settings selector and working nav scrolling, Super+I, three
fixed gentle click sounds, outside dismissal and a larger date calendar.
Nautilus is deliberately untouched pending the requested follow-up question.
The previously pending Settings routing work is included; fresh safe native
captures are now available. Tested changes are deployed by hot reload, with
both shell PIDs retained. Only the explicitly requested legacy OSD/edge behavior
and matching media/brightness bindings were replaced. Wallpaper/autostart and
unrelated services stay intact.

62 Python tests, actual Qt input/selector/weather/music checks, windowless
production compile/router/polling/network tests and existing JS checks pass.
Native surface bounds, SoundEffect Ready states, service ownership and private
WLAN clarity inspected. Physical touch/media setters and compositor input paths
were not automated. [Files, crops, installation, migration and recovery](changes/2026-10-08-interactions.md).
Published `41d2f3a`. Fresh committed-archive verification passes every listed
suite; remote runtime/sounds/Lua controls/native crops match Git blob hashes.
An additional silent Qt click probe verifies SFX and derived actions each run
once. Broader design backlog remains unfinished. The older routing
release-pending entry below is superseded by this combined pass.

## 2026-10-08 / Settings page requests — release pending

Fixed a reproduced native routing bug: requesting Storage while Settings was
already open on General kept General visible. Every open request now signals a
small nonvisual router; repeated requests work even if the requested page string
is unchanged. Deferred requests coalesce to the latest page, and closing before
the callback prevents hidden navigation/focus work. Geometry is unchanged.

10 production-router Qt transitions, 61 Python tests, Settings timer/fixture
tests and existing JS regressions pass. All 14 actual native pages plus repeat
requests, scanner demand and polling intervals verified. Tested source deployed
by hot reload; both shell PIDs, shortcuts, connections and work area preserved.
[Verification, snapshot and release checkpoint](changes/2026-10-08-settings-routing.md).

Publication is not complete. The final capture encountered foreground gameplay;
that frame is private and excluded. Do not interrupt the game for another capture.
Next safe pass: capture the unchanged native Settings material when gameplay is
not foreground, then fresh committed-archive checks and authorized publication.
Preserve this dirty, already-live work; no prompt marked complete.

## 2026-10-08 / Settings background work

Settings now uses its actual page to schedule backend reads: Battery, Brightness
and Storage keep 5-second updates; other pages use 60 seconds. Startup, opening,
page changes and explicit actions retain fresh reads. Closed Settings does not
poll. Live audio/network/Bluetooth/notification service bindings and opt-in
minute usage sampling are unchanged. No UI geometry changed.

Actual windowless Settings timer/process tests cover all 14 page intervals,
startup/open/page refresh, hidden release and fixture suppression. 61 Python
tests and existing JS checks pass. Native General/Storage/closed query counters,
window placement and logs checked; files hot-reloaded without restarting either
shell. [Native output, limitations and recovery](changes/2026-10-08-settings-polling.md).
Published `5de3fd4`; fresh archive passes the timer tests, 61 Python tests and
existing JS regressions. Remote Settings/image blob hashes match. Broader
feature/reference backlog remains pending.

## 2026-10-08 / Sidebar and Settings Wi-Fi discovery

Repaired scan demand: the old network-popup-only assignment missed Sidebar and
Settings. Available, enabled Wi-Fi now scans while a network browser is visible;
General, Calendar and closed surfaces release ghOSt's demand. Sidebar widget
visibility and the actual Settings page control this, including device changes.
No connection, radio toggle or visual geometry changed.

128 policy combinations, 12 windowless Qt binding transitions, 61 Python tests
and existing JS checks pass. Native Sidebar, Wireless Network, General, old
network popup and Calendar states verified. Tested files deployed into the active
ghOSt profile; only the named ghOSt instance restarted for new IPC registration.
Legacy process, connections, shortcuts and 50px reservation preserved.
[Native output, verification and recovery](changes/2026-10-08-network-scan.md).
Published `7bee15a`; fresh committed-archive tests pass and remote policy/image
blob hashes match. Broader feature/reference backlog remains pending.

## 2026-10-07 / Calendar weather loading

Private 15-minute weather cache removes repeat network waits on calendar reopen;
location, timezone-midnight, rollback and expiry invalidate it. No expired-data
fallback or fabricated readings. Tested/deployed the helper only, without a shell
restart or UI/shortcut/wallpaper/autostart change. 61 Python tests and existing JS
checks pass; native current/Today agreement and cache reuse inspected.
[Native output, timing limits and recovery](changes/2026-10-07-weather-cache.md).
No preview-site redesign; broader feature/reference backlog remains pending.

Published `fc2c13a`; fresh committed-archive 61 tests pass and remote helper/image
blob hashes match. Calendar inspection complete, initial closed state restored.

## 2026-10-07 / Product animation

Created the requested short, full advertisement: workspace wheel, scroll-volume
changes, calendar reveal/weather/telemetry/CPU-clock/month controls, grouped
sidebar motion, and Settings General/Battery/Storage/System Info. Actual current
QML components supply the interfaces; demonstration data excludes private chats,
network names and the user's earlier OBS recording. Original projected geometry,
folded planes, moving orbit/grid composition and synthesized mechanical sound
support the monochrome motion-reference direction without copying its footage
or music.

[Film](../assets/ghOSt-advertisement.mp4) ·
[Poster](../assets/ghOSt-advertisement-poster.jpg) ·
[Reproducible source](../scripts/ad/README.md).

Verified: 396 exported native animation frames plus four Settings pages;
projection geometry and continuous scene timeline; full encoded-video decode;
780 frames, 1920×1080 at 30fps, 26 seconds, H.264/AAC. Encoded contact sheet and
individual scene compositions inspected. This is a produced component-demo film,
not an unattended live desktop interaction test. No live audio, workspaces,
configuration or session action changed; only an owned offscreen renderer ran.
Project prompt/design Git blobs were checked against current GitHub main before
production and match the existing recorded hashes. This film does not declare
the broader outstanding Figma/native-feature work complete.

Film and reproducible source are included in this release; no website layout
was changed. Originals and ignored render cache retained; documentation pre-edit copies are in
`.local/ad-production-hq/docs-before/`.

## 2026-10-07 / Sidebar vertical center

Latest correction supersedes the rail-adjacent anchor: vertically center the
whole sidebar on the display, retaining left-edge alignment and15% scale.
Native410×914 at y83 on1080px output gives83px above and below.51 tests pass;
actual placement/logs/capture checked. Snapshot:
`.local/backups/2026-10-07-sidebar-center-aCVKcw/`.

## 2026-10-07 / Sidebar top anchor

Replaced the old144px top offset with rail height plus8px. Enlarged410×914
sidebar now maps at y58, ending at972 on1080px output;15% content scale retained.
51 tests pass; native placement/logs/capture checked. Snapshot:
`.local/backups/2026-10-07-sidebar-position-YTODJM/`.
[Native header](../site/assets/sidebar-status-native.png).

## 2026-10-07 / Sidebar115% scale

Whole sidebar coordinate plane enlarged15%, retaining proportional contents and
its original screen anchor. Uniformly fits smaller displays rather than stretching.
Native window410×914 at1920×1080; right-status70% relative size remains intact.
51 tests pass; native window/logs checked. Only named ghOSt restarted when hot-reload
IPC stopped accepting queries; legacy process, shortcuts, autostart and wallpaper
unchanged. Snapshot:`.local/backups/2026-10-07-sidebar-scale-w048g7/`.
[Privacy-safe native header](../site/assets/sidebar-status-native.png).

## 2026-10-07 / Calendar row hover padding

Full-size weather-row Keys retain the full hover/click area. Scaled row contents
now have6px horizontal inset and centered18px content height, keeping glyphs/text
inside rather than against the hover edge. Width compensates for70/60% scaling so
forecast text is not prematurely elided.51 tests pass; native text/layout capture
checked. Physical hover was not automated. Snapshot:
`.local/backups/2026-10-07-calendar-hover-p3tfTz/`.
[Actual calendar](../site/assets/calendar-native.png).

## 2026-10-07 / Calendar weather synchronization

Current-weather headline and Today row now use the same API observation;
historical/future rows retain daily readings. Forecast scrolling no longer changes
the current headline. Entire forecast rows scale100/70/60% by calendar-day distance
from today, independent of selection. Bottom action corners are7px rather than15px;
main frame/meters unchanged.51 tests pass, including a current-vs-daily mismatch
regression; live London data, native motion/logs and component capture checked.
Snapshot:`.local/backups/2026-10-07-calendar-iSxpER/` includes source/live originals.
[Actual calendar](../site/assets/calendar-native.png).

## 2026-10-07 / Outer gaps and sidebar status only

Latest correction: halve gaps between screen edges and rail, not internal gaps.
Original internal spacing restored; side margins19→9.5px, top gap14.4→7.2px,
50px reserved height. Latest correction: sidebar's right-anchored status group
is30% smaller (70% scale), not50%; settings,
notification and power buttons retain their original size.50 tests pass; native
reload/logs and privacy-safe captures checked. Recovery: rail-gaps and
sidebar-header backups under `.local/backups/2026-10-07-*`.
[Rail](../site/assets/rail-native.png) · [Sidebar header](../site/assets/sidebar-status-native.png).

## 2026-10-07 / Full-width rail correction

Latest clarification supersedes the uniform whole-frame shrink below. Main rail
width/margins restored; contents scale uniformly0.9 in both axes inside the
10%-flatter frame. Left/center/right groups stay anchored; dividers scale with
contents. Network/Bluetooth/battery glyphs and battery text use a common vertical
center.50 tests pass; native hot-reload/logs and full-width capture checked.
Snapshot:`.local/backups/2026-10-07-rail-width-HmeTXH/`; no shortcut/autostart changes.
[Actual rail](../site/assets/rail-native.png).

## 2026-10-07 / Uniform rail scale correction

Latest clarification: the whole rail must scale down, not just its padding.
Applied0.9 uniform scaling to the original coordinate plane, centered on screen;
fonts, icons, controls and gaps now shrink together. Overall reserved height
remains58px.50 tests pass; native hot-reload/logs/capture checked.
Snapshot:`.local/backups/2026-10-07-rail-scale-icNARB/`. Previous compact-padding
description below is historical and superseded. [Actual rail](../site/assets/rail-native.png).

## 2026-10-07 / Compact rail

Reduced vertical rail geometry10%:46→41.4px surface,16→14.4px top gap,
64→57.6px overall design height (58px reserved at1920px). Glyphs, fonts,
horizontal positions and7px corners unchanged. Tested and hot-reloaded only
ghOSt;50 backend and five website tests pass. Native rail captured and Pages
asset updated. No shortcut/autostart/wallpaper/legacy changes.
Snapshot:`.local/backups/2026-10-07-rail-DjS5si/` includes source/live originals.
[Actual rail](../site/assets/rail-native.png). Full prompt remains pending.

## 2026-10-04 / Minimal website and descriptions

Latest direct website request: seven component/motion views, short descriptions,
and a single-page Settings changer instead of a page-card wall. Separated capture,
motion and rendering code; refactored icon helpers and documented focused-function,
clear-name, shallow-flow rules.50 Python tests, five website tests and existing
JS regressions pass; default/mobile layout and browser navigation inspected.
Native desktop unchanged; broader prompt remains pending.
[Output, screenshots and recovery](changes/2026-10-04-website.md).

## 2026-10-04 / Native performance and UI finish

Latest direct instruction: build visibly on this laptop, not in another visual
preview/site. Applied native GPU liquid animation with the original silhouette
and software fallback, cached corner/wave geometry, minute-only clocks and
event-driven work-area measurement with a slower fallback. Refined narrow-label
fades, disabled-control contrast and reduced-motion hover feedback without
changing measured composition/radii/type.50 Python tests plus JS checks pass;
native renderer phases/logs, Settings/window mapping and output inspected.
[Files, actual native screenshots, CPU sample limits and recovery](changes/2026-10-04-performance.md).
Keybindings/autostart/wallpaper and legacy processes preserved. No new preview
website build; broader prompt remains pending. Source publication is recorded
in the change record after verification.

Published source `cd1de19`; fresh Git-archive50 tests/JS checks pass. Four native
screenshots and the shader package match GitHub blob hashes. No preview-site
UI/assets changed; existing push-triggered CI is left intact. Native calendar
and sidebar are open; GPU shaders compile/move with empty logs. Only unrelated
pre-existing untracked files remain outside the release.

## 2026-10-04 / Rail fullscreen behavior

Per-monitor fullscreen hides the rail until exit or a normal workspace.48 Python tests and actual Qt state-transition/dismissal assertions pass; native mapping/logs checked, user confirmed fullscreen works. Prior six Sidebar/Settings/notification/alignment/calendar fixes deployed; spacing/motion/weather rechecks pass. [Output and recovery](changes/2026-10-04-fullscreen.md). Shortcuts/autostart/game settings unchanged; broader prompt pending.

Published source72b60e2; Pages37208796866 succeeded. HTML/script/native screenshot match remotely; fresh archive installation,48 tests and Qt assertions pass. Owned previews closed; ghOSt remains active.

## 2026-10-04 / Settings selection, optical alignment and notification popup

Applied/deployed the six latest corrections: rounded selected Settings row, optical rail clock/calendar and battery alignment, top real-notification popup in both backend modes, empty sidebar without header, keyboard focus/dedicated outside-click mask, and explicit grey calendar outline. [Output, verification and recovery](changes/2026-10-04-dismissal.md).48 Python tests, actual isolated Qt Escape/pointer events, Settings/spacing/motion/calendar and JS checks pass. Native types/logs and real360×96 notification mapping checked; existing owner/legacy services preserved. Physical compositor input automation and broader prompt gaps remain pending.

Published source61a00ea and preview cache correction557c4e2; Pages run37207613146 succeeded. Fresh tracked installation/48 tests/input assertions pass; all26 changed public assets byte-identical, live Notification popup selection loads. Private desktop captures retained locally; owned preview closed and desktop returned to its prior closed-panel state.

## 2026-10-04 / Rail, sidebar, Settings and calendar spacing

Latest eight corrections applied and deployed: roomier clock, aligned22px right glyphs, root Escape dismissal,40% Settings glyphs,52px rows/16px groups,18px name-pencil gap and12% larger820×347 calendar. Runtime QML expanded with Qt6 formatting; complete source/installer documented and fresh isolated install byte-tested. [Output, verification, source and recovery](changes/2026-10-04-spacing.md).47 Python tests, spacing/corner geometry/pixels,14 Settings pages/flows, sidebar/calendar motion and JS regressions pass. Fresh-release testing caught and fixed notification filter ownership; five notification-suite passes plus fresh Git-archive installation/full47 tests pass. Native output/logs inspected; only named ghOSt restarted. Shortcuts/autostart/wallpaper/legacy preserved. Physical pointer/keyboard automation and broader backlog remain honestly pending.

Published UI release `e6e06d6` and backend correction `7311088`; Pages run37204033956 succeeded. All30 changed public assets match local bytes; the public Settings preview loads. Panels subsequently closed by desktop interaction remain closed; rail active, notification observer ready, owned fixture stopped.

## 2026-10-04 / Figma corner renderer corrected and live

Replaced the nearly-square single-cubic renderer with shared radius/smoothing paths and matching portrait/meter/slider clips. Editable Figma confirms Bluetooth15/11px at0% smoothing and Settings portrait21px/main frame10px at60%. Settings grey/icon materials use10/8px G2; selected navigation strip is square. [Files, screenshots, tests and recovery](changes/2026-10-04-corners.md).45 Python tests, JS geometry, actual pixel assertions and Settings/sidebar/calendar regressions pass. Only ghOSt restarted; native output inspected/logs clean. Binds/autostart/wallpaper preserved. Full prompt remains pending for broader recorded gaps.

Published source976fbf0; Pages run37201326308 succeeded. All30 changed output/HTML/script/wallpaper assets verified byte-identical remotely. Public Settings/Sidebar load new output; owned fixture closed, native ghOSt panels left open.

## 2026-10-04 / Requested desktop-visible corrections

Latest direct authorization supersedes staging-only delivery for the requested ghOSt surfaces. Deployed tested rail/sidebar/calendar/Settings corrections to the existing ghOSt profile and restarted only ghOSt. Added left-group divider lines, independent notification server/observation/history/dismissal, and a stale-focus fix for opening Settings. Requested radii, grouped Settings/portrait/PC-name/creator flows, larger statuses, left-to-right entrances and cylindrical workspace wheel are now deployed. [Output, verification, rollback and remaining limits](changes/2026-10-04-desktop.md).

45 Python tests,15 launcher assertions, JS wheel checks,14 Settings-page/flow captures and rail/sidebar/calendar motion checks pass. Native ghOSt logs clean; Settings mapped1024×699 and real notification observation works without replacing its owner. Shortcuts/autostart/wallpaper unchanged. Public renders use samples; native captures remain private. Same ACTIVE five-hour weekday heartbeat now carries desktop-visible authorization. Full prompts.md remains pending for broader recorded gaps; no100% parity claim.

Published source `a953a7e`; Pages run37199503178 succeeded. Remote changed screenshots, HTML/script and wallpaper match local exports; Sidebar preview visibly loads. Responsive390px layout has no horizontal overflow.

## 2026-10-04 / explicitly requested Sunday workspace build

Staged the detailed cylindrical workspace wheel, stable triangle/hit targets, continuous mid-turn retargeting, eligible displayed neighbors and fractional/multiple-notch scrolling. Added actual QML motion/still captures and reduced-motion web preview. [Output and verification](changes/2026-10-04-workspace-wheel.md). 41 Python tests, 15 launcher assertions, JS projection/ring tests, native QML fixture motion/input-model checks and prior Settings/sidebar/calendar regressions pass. Active desktop, shortcuts/autostart and existing processes unchanged; no automatic activation. Published source `0b19c9e`; Pages run37193540728 succeeded and static output bytes match remotely. Full prompt remains pending for left rail alignment/dividers, independent notifications/lock and other gaps.

## 2026-10-04 / scheduled Settings correction pass

Published source release `bcd8e3e`; Pages run37171957777 succeeded. Live HTML/new Settings controls loaded; all changed screenshot/wallpaper/pencil assets matched local bytes. [Publication details and browser-check limits](changes/2026-10-04-settings.md#publication).

First requested 03:20 London run restored the same heartbeat to five hours; future substantive builds remain weekdays. Staged four Settings category frames, both picture-chooser entry points/private original-preserving copies, validated deliberate PC-name edit flow, measured pencil placement and exact creator Info. Added standalone two-tone pencil SVG (61 icons). Preserved and regression-tested preceding exact-reference/manual sidebar/calendar/rail changes. [Output, files, checks and remaining gaps](changes/2026-10-04-settings.md).

41 Python tests,15 launcher assertions,14 Settings pages plus portrait/name/search flows, runtime rail/sidebar checks, calendar motion,61 two-tone SVG checks and isolated installer passed. Actual fixture captures exclude private network/chat data. Active desktop/config/autostart/keybindings unchanged; no real hostname or power action executed. Publication verification is recorded in the change record. Full prompt remains pending for notifications/lock, 3D wheel, left rail dividers and other gaps; no 100% parity claim.

## 2026-10-04 / small manual corrections staged

User requested some work now. Corrected sidebar grouped left-to-right entrances,15/11 px corners and larger aligned right-anchored status icons; calendar action radii; all-Nerd rail fonts/date fit and centered workspace triangle. [Changes, actual screenshots and remaining gaps](changes/2026-10-04-small-corrections.md). Runtime polish checks,14 Settings pages, calendar animation/weather checks,36 Python tests,15 launcher assertions and isolated installer pass. Only the owned isolated preview was started/stopped. No live change or publication; full prompt remains pending.

## 2026-10-03 / stopped; latest corrections queued

Next scheduled start: **03:20 Europe/London, 2026-10-04**. [Latest authoritative corrections](next-scheduled-corrections.md) supersede conflicting earlier notes. Existing dirty source/output is preserved; final regression was interrupted and newer screenshots are unpublished. No UI/live-desktop change in this checkpoint. Existing heartbeat updated and active; its first 03:20 run restores the previous five-hour weekday workflow. Prompt revisions remain pending.

## 2026-10-03 / Desktop 1 and Settings exact-reference pass

Both Figma desktops inspected. Staged measured plain-font loading, original portrait crops, sparse General layout, compact navigation/search/separators, right-anchored sidebar statuses and three-button header, rail fill/dividers, and restored 733 × 310 calendar geometry. Isolated preview uses the measured Settings origin (524,212). [Changes, screenshots, verification and remaining parity gaps](changes/2026-10-03-exact-figma.md). No active desktop/autostart/config/process change in this pass under current AGENTS.md. Do not claim 100% parity or mark the prompt revision completed. Continue from these source changes; the previous live deployment is unchanged.

## 2026-10-03 / Settings and rail-autostart transition

Continued the manual pass. Fourteen-page Settings and the latest rail/calendar/sidebar polish are implemented and isolated-tested. The user's new direct request authorized the live rail-autostart replacement: ghOSt is running, the previous rail is disabled, and its unrelated services remain active. Native Settings is 1024 × 699; transparent reservation now protects 64 px, calendar is 806 × 310 and existing binds are unchanged. [Change record, screenshots, recovery and remaining gaps](changes/2026-10-03-settings-polish.md).

36 Python tests, 15 launcher assertions, isolated Settings/sidebar/calendar checks and default staging install passed. Native QML logs, layers, work area and private screenshots were inspected; no setters or disruptive actions were executed. Release `6c500a7` was pushed; Pages workflow `37155289952` succeeded. The live site loaded the new Settings controls and 1100 × 760 screenshot; a 390 px browser layout had no horizontal overflow. The prompt revision remains pending for the explicit gaps, not completed.

## 2026-10-03 / manual polish paused; schedule resumed

The user requested stopping now and carrying unfinished work into the existing weekday five-hour schedule. [Continuation checkpoint](pending-polish.md) records partial G2/material/calendar/sidebar/workspace changes, exact measured new Settings nodes and remaining verification. The full Settings app is not built; the rail work-area fix is not verified. Most polish remains staged. No new publication or completed prompt revision is claimed. Preserve current dirty work and snapshots. The scheduled prompt was updated with latest Figma and user corrections and resumed as ACTIVE.

## 2026-10-03 / measured Figma implementation

Supersedes earlier sidebar staging notes: the user directly requested applying and launching the sidebar, rail and full calendar. Inspected the signed-in Figma's nested layer properties, fonts/weights, dimensions, colors, stroke alignment, radii and gradient stops. [Measured specification](figma-spec.md). Rebuilt the rail on a 1920 × 1080 coordinate plane; calendar is 733 × 310; sidebar background is 391 × 790 with its left 37 px outside the artboard. WLAN/Bluetooth now have the measured housing, list well and cap layers. Inner card radius is 15 − 4 = 11. Added bundled Turret Road Regular/Medium, corrected the calendar gear icon and instrument type, and straight-ended clipped slider fills.

The tested ghOSt rail/calendar/sidebar were installed and opened by direct user request; only the named ghOSt process was restarted. Existing rice process, keybindings, wallpaper and autostart were preserved. Rail uses an overlay layer so another installed shell cannot intercept it; calendar/sidebar share a focus group so opening one does not dismiss the other. London weather and real telemetry remain connected. Brightness on HDMI and notifications without an independent daemon are honestly unavailable. Full Settings, notification history, independent lock and the remaining old-rice audit are pending.

Verification: 15 Python tests, 15 launcher assertions, 60 two-tone icon parity checks and the isolated calendar animation/ratio check passed. Native ghOSt loaded without QML warnings; visible layers and private live screenshot were inspected. Bind JSON SHA-256 before/after this pass: `ec0f696afa82d444033071247e554ef4675897d570b5954c4eb9cdea5f45b2b5`; Hyprland config errors empty. IPC exercises the same open handlers as the controls; physical Wayland mouse-click automation remains unverified. No power/session action executed.

Prompt/design hashes remain `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d` / `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`. Clean actual-QML captures: [composition](../site/assets/desktop-frame.webp), [calendar](../site/assets/calendar-frame.webp), [sidebar](../site/assets/sidebar-frame.webp), [rail](../site/assets/rail-frame.webp). These label sample data and do not expose nearby network names or desktop chat. The site wallpaper was separately exported from the currently selected laptop wallpaper; the original was not changed. Local snapshot: `.local/backups/2026-10-03-figma-pass/` (project and installed ghOSt paths). Copy its installed snapshots back into the named ghOSt configuration and restart only ghOSt for rollback; new profile-only assets can remain unused. The user prompt stays pending for the explicitly listed gaps.

## 2026-10-03 / sidebar slide

Follow-up: fixed the installed shell's missing Sidebar instance and connected the rail menu button to toggleSidebar. The previous animation-only change had not activated the sidebar. After reload, opening through that same toggle created the visible 360 × 800 ghost-sidebar layer at (16,82).

Applied a 280 ms left-to-right slide to the running ghOSt sidebar and matched the staged component. Reduced motion remains immediate. The live Quickshell configuration reloaded successfully; direct pointer verification was unavailable. Only the sidebar animation was activated. Backups: `.local/backups/2026-10-03-sidebar-slide/`.

## 2026-10-03 / reference-matched frame refinement in progress

The 2026-10-03 annotated screenshots establish the intended composition. The tested live rail and calendar now use 7 px outer radii; the calendar is 733 × 308 px on the 1920 × 1080 monitor, directly below the 46 px rail. The calendar font sizes were corrected after inspecting a native crop. Its weather comes from the user-selected London location, real CPU/GPU/RAM/processor readings drive the liquid meters, and the storm/rain motion was exercised in an isolated fixture. The workspace control is a three-position wheel. Rail controls use ghOSt SVG icons; the compact power HUD opens without invoking any power action and requires a second confirmation click for disruptive commands. Lock is explicitly unavailable until an independent ghOSt lock configuration exists.

An independently authored left sidebar is staged with 7 px outer radius and nested radius computed as `max(0, outerRadius - padding)`. It contains Wi-Fi/Bluetooth lists, volume, brightness status and a notifications status area. It was inspected on the live desktop during development but removed from the live shell because the user's earlier activation approval covered only calendar and rail; separate approval was requested for sidebar activation. The installed rail therefore retains its preexisting network/Bluetooth/battery panels until approval. Sidebar brightness remains unavailable on the current HDMI display (no usable DDC display), and a notifications service was unavailable; neither value is fabricated. Settings is currently a small functional control overlay, not a complete Settings app.

Verification: GitHub `prompts.md` and `mainDesigns/Screenshot 2026-09-30 212732.png` matched local blob hashes `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d` and `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`. Fifteen Python tests and fifteen launcher assertions passed. Isolated QML preview loaded; IPC verified random reveal ordering, 1.5 s completion, rain motion, periodic storm lightning, reduced motion and stopping animation when closed. Native Quickshell reloads reported `Configuration Loaded`; `hyprctl configerrors` was empty and the live bind JSON SHA-256 was unchanged (`b2b4875462ecbc112533f0a6c6101116d715b1870ed98cf4c95b37c931de0651`). Native panel layers and cropped screenshots were checked. Physical mouse clicks on the Wayland rail and all sidebar list actions were not independently automated.

Local evidence: `.local/verification/calendar-refinement/calendar-native-final-crop.png`, `calendar-final-preview.png`, `sidebar-final-preview.png`, `power-final-preview.png`, `rail-final-preview.png`, `site-desktop.png`, `site-mobile.png`, and `power-native.png`. The older `sidebar-7 px-live.png` contains real nearby SSIDs and must never be published. Public-ready sample-data renders are `site/assets/{calendar,sidebar,power,rail}-frame.webp`. Snapshot: `.local/backups/calendar-refinement/`. The previous entry below describes the earlier staging point and is superseded where activation or weather status differs.

Commit `b935b77` was pushed and the [Pages preview](https://dsksnkz.github.io/ghOSt/) deployed successfully; the live HTML and all four screenshot assets returned HTTP 200. [Change record](changes/2026-10-03-frames.md). Remaining before full prompt delivery: obtain sidebar activation answer; finish the old-rice dependency audit (the untouched staged `config/hypr/hyprland.lua` still has references, and some older components may too); build an independent lock entry and notification surface; verify direct Wayland pointer interaction. The installer no longer rewrites another rice's shell. Do not mark `prompts.md` complete yet. The next scheduled run should continue this work, without usage-threshold deferral.

## 2026-10-02 / calendar frame local staging

Continued the existing unfinished implementation of the user's full mainDesigns frame: weather left, GPU/RAM/CPU liquid diamonds centrally (CPU switches to clock), calendar right, bottom controls and the visible rail clock/date/weather group. Added flat panel material, reduced-motion reveal handling, inner-panel Escape handling and functional launcher navigation. Rail tooltip text remains disabled with accessible names retained. Frame drop uses 220ms; six subframes reveal in randomized order over 1.5 seconds. Waves and sampling stop when closed.

Verified local prompt/design blobs against GitHub: f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d / 9cc34c7e555a0cbfbff777d194a13ac3b799e6fe. Fifteen Python tests and fifteen launcher assertions pass. Isolated QML loads without component errors; month navigation, randomized reveal order, reduced motion, clock switching and close state checked through preview IPC. Screenshots: .local/verification/calendar-evening/calendar-full-frame.png (explicit sample data) and calendar-real-readings.png (live metrics). Snapshot: .local/backups/calendar-20261002-evening/; final-pass component snapshot also retained.

No active configuration changed or activation performed. Weather needs a user-selected location; no live forecast validation claimed. Power actions are deliberately unavailable in staging; Settings contains reduced-motion and location guidance, not a complete settings application. Native pointer/keyboard behavior and frame timing on Wayland still need isolated interactive verification. No publication this pass. hyprland.lua work was stopped at the user's request and its earlier staged file remains untouched.

## 2026-10-02 / 0.3.1 assets staged

Published 60 standalone SVG icons in black and white, a QML wrapper and isolated catalogue, and a searchable responsive download gallery. Nine Python tests (including 240 raster checks), 15 launcher assertions, and all 120 QML icon images passed. No live desktop activation. See [change record](changes/2026-10-02-svg-icons.md).

Remaining: supplied calendar composition/motion, rail tooltip removal, terminal reference matching, compact power HUD, and complete removal of old-rice runtime dependencies. prompts.md remains pending, not completed. Usage at start 0% five-hour / 16% weekly; publication preparation 52% / 24%. No reset credit used.

## 2026-09-30 / 0.3.0 staged

Added the independent launcher: ranked native application search, bounded keyboard selection, persistent pins, empty results, and six new monochrome icons. The G control and session launcher action now target this component in staged source. No shortcut changed. Actual component renders and Pages cover launcher, search, empty results and the expanded icon pack.

Checks: 15 launcher assertions, six telemetry tests, isolated QML load, 112 desktop entries, pin persistence after restart, selection boundaries, preview-safe launch dispatch, staging installer, unchanged live bind JSON and native PIDs. Desktop and 390 px web layouts reviewed. Native keyboard events and actual app startup remain untested; the installed older bar is unchanged.

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
