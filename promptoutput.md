prompts outputs here

## 2026-10-25 / Animation pass

User: "still jittery, feels low on fps. also review all animations ... at least
60fps". Root cause measured (setup frames at animation start); gated reveals and
still-window launcher deployed. Calendar deferral pending deployment (CS2 running).
Record: docs/changes/2026-10-25-animation-pass.md.

## 2026-10-25 / Media slide jitter

User: "its jittery, fix". Slide moved from per-frame window margins to a
fractional content offset in a still window; deployed with one clean reload.

## 2026-10-25 / Media popup slide

User: "change the animation from the tray scaling bigger to the tray sliding
from top to bottom, only for the audio tray". Implemented and tested; deployment
held while CS2 ran, then deployed on "I'm done playing" with one clean reload.

## 2026-10-25 / Rail marks removed

User: "remove the little 'lines' at the bottom of the top bar, and the the square
surrounding the clock top bar". Day scale and clock corners removed; deployed.

## 2026-10-25 / Spacious calendar and audio bar

User: "the ui seems cramped abit in space. redesign in a more modern ui. also
redesign the audio bar in top bar". Calendar enlarged to 820 × 380 with header and
whitespace. Correction: "change the bar which appears after clicking the audio
element ... not change the audio element top bar" — rail element restored; new
MediaPanel popup. Tests pass; deployed with clean reloads.
Record: docs/changes/2026-10-25-spacious-calendar-audio.md.

## 2026-10-25 / Rail and calendar redesign

User: "remake the calendar bar / the top tray using your own design. dont overload
the features, keep it minimalist, but zero AI ui slop. add style". Scope: rail and
calendar, deploy when tested. Monochrome instrument style, no new features.
Tests pass; deployed with one reload. Live calendar popup visual not opened.
Record: docs/changes/2026-10-25-rail-calendar-redesign.md.

## 2026-10-25 / OSD exit range and animated scroll volume

User: "make the it only dissapear after leaving the range abit more, and scroll
to change volume with osd animations". Open retention extends 72px inward and
includes popup hover/active slider drag, with 100ms exit grace. Inactive trigger
stays 2px and 0.2s; spawn height remains latched. Input-mask cutout preserves OSD
controls. Wheel works over expanded edge or popup, 2% steps, with 120ms fill and
number animation; reduced motion/drag are immediate. Production nonvisual state
tests cover release grace and quick reentry; pure geometry/search tests and
surface compile pass. Deployed exact modules; clean reload logs. No native
pointer/game/volume manipulation or screenshots. Native interaction/visual
verification remains pending normal use. Record: docs/changes/2026-10-25-osd-range.md.

## 2026-10-25 / Dwell0.2seconds

User: "change the time to 0.2s." Updated EdgeHold.dwellMs to200, matching Intro
help, docs and test timings. Real nonvisual production timer/state tests pass;
fixed placement/hold/exit and normal keyboard expiry unchanged. Deployed only
EdgeHold and IntroTopics, with exact originals snapshotted under
`.local/backups/2026-10-25-edge-200ms/`. No cursor or game interaction.

## 2026-10-25 / 0.5s dwell, fixed placement, close on edge exit

User: "change the osd to: it appears in the position of the cursor when touched
the edge of the screen for 0.5s, then stays on the edge until mouse moves out of
edge. it dosent follow the cursor vertically after already spawned".

Implemented nonvisual EdgeHold500ms dwell/latch; early exit cancels. OSD samples
Y at activation and holds it, stays visible without2.2s inactivity expiry, closes
when leaving. No motion tracking timer. Pre-dwell clicks/wheel cannot bypass the
delay; post-dwell scroll keeps2% steps. Keyboard OSD retains normal timeout/slider.
Headless production state/timer tests with fake services pass, including remaining
visible past2.2s, audio updates not moving it and release/reentry. Pure JS/compile
pass. Deployed six modules and confirmed one clean automatic reload, no manual
extra reload or physical cursor/game interaction. Screenshots/native pointer
verification deferred during gaming; no claim those were performed. Recovery and
evidence: docs/changes/2026-10-25-edge-dwell.md.

## 2026-10-25 / Activate full-height pointer-aligned OSD

User: "activate". Low-priority production compile passed. Snapshotted exact six
live files to `.local/backups/2026-10-25-osd-activation-UntdRK/`, deployed only those
modules, confirmed one automatic reload/Configuration Loaded. Live read-only
edge geometry is top0,height1080,width2. No additional reload, cursor movement,
popup, screenshot, game change or heavy/interactive test. Native pointer position
checks remain pending; fullscreen edge suppression is preserved during gaming.

## 2026-10-25 / Full-height edge OSD; gaming-safe continuation

Latest requests: align edge OSD vertically with the pointer, stop lagging the
laptop, and trigger anywhere on either edge rather than only the center; work
in background while user plays CS. Full-height2px triggers and pointer-derived
clamped placement are implemented in project source. Pointer tracking is bounded
to one update per16ms while active. No volume change on hover; existing fullscreen
edge suppression remains. Intro help now describes full-height behavior.

An earlier pointer-position pass was deployed before the gaming clarification;
native test attempts did not pass because synthetic input did not reliably reach
requested coordinates. Those results are not verification. No helper test process
remains running. Latest full-height revision is deliberately NOT copied live or
reloaded during CS. Only low-priority pure JS tests and diff checks were run;
full-height native verification, new captures and activation remain pending.
Updated native helper refuses pointer tests if CS2 is running. No game settings,
network, unrelated services or hardware changed. Record: docs/changes/2026-10-25-full-edge-osd.md.

## 2026-10-24 / Special-workspace fullscreen hiding

Request: "the top bar still shows when fullscreened some stuff".

Actual inspected state: browser fullscreen2/client2 on visible special:music,
while the monitor's normal active workspace was nonfullscreen. Rail only read
the latter. Fixed shared FullscreenState to include the special workspace shown
on that monitor, never hidden specials. Edge volume inherits this fix. Special
and fullscreen events refresh Quickshell IPC models with20ms debounce, no poll.
Deployed three affected files and reloaded named ghOSt. Existing fullscreen app
left unchanged; native rendering reports railVisible:false and compositor layers
contain neither ghost-bar nor its edge targets. Real Qt tests exercise normal/
special transitions, restoration, hidden/unrelated specials and null monitor.
No application fullscreen toggle, shortcut, reservation, geometry or service edit.
Recovery, capture and verification: docs/changes/2026-10-24-special-fullscreen.md.

## 2026-10-24 / Rail corrections, edge volume and Intro

User requested: Wi-Fi artwork even on Ethernet; equal icon heights per control
class; unclipped sidebar100%; white workspace dot; no rail volume, replaced by
middle-only left/right edge OSD with dead zones; remove sidebar edge opener; and
a searchable, recommended-first ghOSt Intro app that opens floating/windowed.

Implemented all listed surfaces. Old rail layouts migrate without changing other
element order/zones or preferences. Intro has7 searchable tutorials,3 recommended
starting topics, explicit buttons, real keyboard search/empty/reset/Escape, app
entry/icon and narrow floating/client-fullscreen-suppression rule. No automatic
preference choices or intro autostart. Taste skill applied to hierarchy/contrast,
not conflicting website hero/GSAP defaults.83 Python tests and real Qt/native
checks pass. Native edge checks cover both sides/dead zones/expiry, without
clicks or volume changes, restoring the pointer. Actual Intro is floating860×620,
fullscreen0; GIO launch and native content capture succeed. Only ghOSt modules,
app entry/icon and its exact compositor rule deployed; safe captures refreshed.
No keybinding file, network, package, hardware/session/authentication change.
Details, limits, backups and screenshots: docs/changes/2026-10-24-rail-edge-intro.md.

## 2026-10-09 / Super+L launch repair

User reports "super l dosent do shit". Actual launch logs show the lock scene
cannot import G2Surface when its entry is inside the nested lock directory.
Moved the entry to `ghost-bar/lock.qml`, preserving shared components inside
Quickshell's scanned root; explicit ghost-lock ShellId remains separate from
the bar. Updated Super+L, power-key Lock, wlogout and ghOSt Lock menu routes.
Correct-root compile and visual/input/mock-auth checks pass; live files and Lua
verified. Real compositor lock/unlock remains user-verification pending.

## 2026-10-09 / Venetian blinds lock

Request: descending venetian blinds with Bézier speed; typing blurs the blinds
away and brings in a digital clock/password input; success rotates the slats
to reveal the desktop, then removes them rather than lifting the blinds.
Implemented independent session-lock/PAM entry, visual scene, authentication
controller and authenticated exit overlay. Installed and connected to existing
lock routes. Existing PAM service reused unchanged; no actual lock invoked.
Animation/input/mock-auth tests, production compile, existing Qt suite, Lua and
live file parity pass. Screenshots are explicitly safe Qt test renders.
Real authentication/secure unlock/multi-output handoff require normal user
verification; this part is not claimed fully verified or broad prompt-complete.
[Files and frames](docs/changes/2026-10-09-venetian-lock.md).

## 2026-10-09 / Forecast switch transition

Request: "every scroll or change in the calendar bar, the top actual weather
should blur out then back, to show that it changed. also the scroll menu's left
needs to be aligned with the weather's left".
Forecast wheel/clicks and headline data changes blur/fade the entire weather
headline for300ms, switching data at110ms. Rapid input keeps the latest selection;
reduced motion is immediate. Forecast and headline left edges aligned, hollow
arrow outside the rows. Qt transition/input/compile checks pass; real desktop
blur and sharp states verified and captured. Tested version deployed.
[Output](docs/changes/2026-10-09-weather-transition.md).

## 2026-10-09 / Remove rail calendar icon

Request: "remove calendar icon on top rail". Removed the glyph while preserving
clock/date/weather layout and click-to-open calendar behavior. Compile passed,
deployed and native output inspected; source/live files match.
[Evidence](docs/changes/2026-10-09-rail-calendar-icon.md).

## 2026-10-09 / Left rail dividers

Request: "remove the horizontal lines between the three bars on top left,
desktop swither and music". Removed the two inter-group separator surfaces,
preserving component positions and right-side separators. Compiled, deployed
and inspected actual native output; source/live match.
[Evidence](docs/changes/2026-10-09-left-dividers.md).

## 2026-10-09 / Rail music:15 background bars and larger title

Direct request: move Cava from the left to the background of the whole music
element, use15 bars and increase only music text in the top rail.
Implemented/deployed15 real mono Cava bands behind compact music,9→13px title,
6px title inset, existing controls/progress and expanded panel preserved.
Qt input/compile and raw Cava frame checks pass; live process/native output
inspected. Private media title excluded from the published native crop.
[Record](docs/changes/2026-10-09-music-background.md). Published `9abd448`;
remote main and runtime QML blobs verified. This request is delivered; no broader
prompt completion claim.

## 2026-10-09 / Click-sound volume and choices

Added volume/mute, independent rail/sidebar/Settings choices, local custom WAV
import and preview buttons at the top of Sound. Defaults preserved; media volume
and system settings are unaffected. Persistent private copies/preferences,
cancelled selection and invalid files handled.71 tests plus Qt/JS checks pass;
active native output/Ready states verified and Sound opened for direct inspection.
[Record and actual screenshot](docs/changes/2026-10-09-sfx-settings.md).
Published `9490dea`; remote revision/seven runtime/test/native-image blobs
verified. Fresh archive passes71 tests, silent Qt input/compile and generator.
This request is delivered; broader prompt remains unfinished.

## 2026-10-09 / Settings and Settings sidebar

Taste Skill's applicable audit, spacing, hierarchy and contrast guidance adapted
to native ghOSt, preserving owned icons and existing functions. Both panes
refined: larger searchable sidebar, stable selections, live General summaries,
grouped controls and readable values. Original portraits/name flow, creator
attribution, all14 pages and scroll/motion remain. Tested/live on the laptop;
64 Python tests, Qt and JS checks pass. Six privacy-safe actual-output captures
and [full record](docs/changes/2026-10-09-settings-taste.md). Published `3be085f`;
remote revision and twelve runtime/test/native-image blobs verified. Fresh
archive passes64 tests, generator and Qt suites; broader prompt remains unfinished.

## 2026-10-09 · All icons and Settings redesign

All64 ghOSt icons share rounded inner/outer corners and2px outlines. New Settings
header follows the screenshot/editable Figma; latest corrections remove lines,
add16px search-to-list space and6px inter-row gaps, and suppress selected hover.
All14 pages, header actions/search, scroll and Bézier selector remain functional.
Tested/live on the laptop, preserving both shell processes and unrelated configs.
64 Python tests plus Qt and JS checks pass; native Settings/Calendar/rail images
are in the [change record](docs/changes/2026-10-09-icons-settings.md). Published
`dc20fdd`; all icon/native image blobs and remote revision verified. Fresh archive
passes64 tests, generator and Qt input/compile; broader prompt remains unfinished.
Safe native Sidebar header included;
private list/chat captures are excluded.

## 2026-10-09 · Redo the inside folder corners

Deleted the rejected layered experiment (recoverable from Git/snapshot) and
replaced the earlier rounded outline with explicit rounded inner tab/body
cutouts. Black/white variants and preview share one generator geometry. No
Nautilus changes. All 63 Python tests, generator freshness and diff checks pass;
rendered inner corners visually inspected. Published `ffabbe7`; remote revision,
six asset blob hashes and removal of layered assets verified. Older variants below are
historical, not the current design.

## 2026-10-09 · Shaded, layered folder

Added the requested 3D-like grey shading with a dark rear/tab and lighter middle
front, rounded layers, rim lighting and a soft shadow. Standalone transparent
SVG/512px PNG are in `assets/folder-layered.*`; flat variants remain intact.
Small/large raster checks pass and output inspected. No Nautilus activation.
All 64 Python tests and flat-pack generator checks pass. Published `6017a49`;
remote revision and SVG/PNG blob hashes verified.

## 2026-10-09 · Rounded folder icon

Added one rounded folder design in black/white transparent SVG variants, keeping
the original icon unchanged. Preview: `assets/folder-rounded-preview.svg`.
No Nautilus theme or desktop configuration was applied. All 62 Python tests and
generator freshness checks pass; raster preview inspected. Published `ecf2799`,
with remote revision and all four SVG copies verified against their blob hashes.

## 2026-10-09 · OSD and actual outside dismissal

Fixed the real compositor path, not just the Qt callback: Sidebar now uses
OnDemand focus, and native left/right/middle outside clicks plus immediate
Escape pass without underlying click-through. Calendar/Media pass too. Removed
the legacy OSD instance and verified its configuration finally hot-reloaded;
both shell PIDs remain. The ghOSt vertical slider has no horizontal cap;
follow-up tighter horizontal padding and darker card/track are included.
62 tests and production compile/input checks pass; safe native crops inspected.
[Evidence and recovery](docs/changes/2026-10-09-osd-dismissal.md).
Published `aea9b3e`; fresh archive checks and remote/runtime/image hash verification
pass. Every completed verified ghOSt change is to be published.
Nautilus and the broader backlog remain untouched/pending.

## 2026-10-08 · Native interaction pass

Eleven requested desktop changes are implemented and live. Nautilus remains
untouched, as requested. The direct prompt is preserved in
[requests](docs/requests/2026-10-08-interactions.md). New music controls, crisp
WLAN list, independent left OSD/edge, weather switcher, Settings motion/scrolling,
Super+I, gentle per-surface clicks, outside dismissal and enlarged date grid are
covered in the [change record](docs/changes/2026-10-08-interactions.md).
62 Python tests, actual Qt event/geometry checks, windowless production
compile/router/polling/scan tests and existing JS checks pass. Native deployment
and privacy-safe crops verified; no hardware/media setter executed in tests.
Physical touch and compositor pointer paths remain unautomated. Published
`41d2f3a`; fresh archive passes all listed checks and remote runtime/sounds/Lua
controls/native crops match their blob hashes. A silent Qt click probe verifies
base SFX plus derived action dispatch. The broader design prompt is not completed.

## 2026-10-08 · Settings page requests — release pending

Requests now navigate an already-open Settings window, including repeated page
requests. Rapid requests coalesce; closed windows ignore deferred work. 10 actual
Qt router transitions, 61 Python tests, timer tests and JS regressions pass;
all 14 native page routes/scanner/polling states checked. Deployed by hot reload.
[Evidence and recovery](docs/changes/2026-10-08-settings-routing.md).
Final screenshot/publication pending: foreground gameplay interrupted capture,
so no further desktop inspection is performed while the game is active. Private
gameplay frame excluded. Broader prompt and this release remain unfinished.

## 2026-10-08 · Settings background work

Less backend polling on static/service-driven Settings pages; Battery, Brightness
and Storage retain 5-second updates. Opening and page changes refresh immediately,
closed Settings stops periodic reads. Actual windowless Qt tests, 61 Python tests
and existing JS checks pass. Native counters/output verified; deployed by hot
reload, no process restart or layout change.
[Verification and recovery](docs/changes/2026-10-08-settings-polling.md).
Published `5de3fd4`; fresh archive tests and remote Settings/image hashes verified.
Broader prompt remains unfinished.

## 2026-10-08 · Sidebar and Settings Wi-Fi discovery

Network discovery requests now follow visible Sidebar and Settings network lists,
not just the old popup. Hidden browsers stop ghOSt's scan demand. 128 policy cases,
12 windowless Qt transitions, 61 Python tests and existing JS checks pass; actual
native scanner states checked. Deployed to active ghOSt, preserving connections,
shortcuts and legacy processes. No layout or radio/profile changes.
[Actual output and recovery](docs/changes/2026-10-08-network-scan.md).
Published `7bee15a`; fresh archive tests and remote policy/image hashes verified.
Broader prompt remains unfinished.

## 2026-10-07 · Calendar weather loading

Calendar reopen reuses a private recent observation; 15-minute expiry, location
changes and local midnight refresh it. No stale-after-expiry fallback. 61 tests
and existing JS checks pass; helper installed, native weather agreement inspected.
[Actual output and verification](docs/changes/2026-10-07-weather-cache.md).
No visual design, website or unrelated system changes; broader prompt pending.

Published `fc2c13a`; fresh committed-archive 61 tests and remote helper/image hashes
verified. Calendar restored to its initial closed state after inspection.

## 2026-10-07 · ghOSt advertisement

[26-second film](assets/ghOSt-advertisement.mp4): native desktop-wheel and sidebar
animation, rail volume scrolling, calendar/weather/metrics/month controls, and
Settings General, Battery, Storage and System Info. Monochrome projected planes,
orbital geometry and original sound.1080p/30fps; sample data, no private recording
or reference music reused. All 396 native sequence frames verified, encoded 780
frames decoded successfully, all scene compositions reviewed. Live desktop and
audio unchanged. [Source and reproduction](scripts/ad/README.md).

## 2026-10-07 · Centered sidebar

Sidebar vertically centered, still left-aligned and15% enlarged. Verified y83,
height914 on1080px display (83px above/below);51 tests pass, native logs clean.
Recovery:`.local/backups/2026-10-07-sidebar-center-aCVKcw/`.

## 2026-10-07 · Sidebar placement

Sidebar anchored8px below the rail, not at the old144px offset. Native y58,
410×914, retaining15% enlargement.51 tests pass; actual mapping/logs checked.
Recovery:`.local/backups/2026-10-07-sidebar-position-YTODJM/`.

## 2026-10-07 · Sidebar enlargement

Sidebar and all contents15% larger, proportional and screen-fitted; anchor unchanged.
Native410×914 window checked;51 tests pass. Only ghOSt restarted for IPC recovery.
[Actual header](site/assets/sidebar-status-native.png); full captures with private
network names are not published. Recovery:`.local/backups/2026-10-07-sidebar-scale-w048g7/`.

## 2026-10-07 · Calendar hover rows

Full-row hover/click boxes with inset, vertically centered icons/text; smaller
forecast rows retain available text width.51 tests pass; native layout checked,
physical hover not automated. [Actual calendar](site/assets/calendar-native.png).
Recovery:`.local/backups/2026-10-07-calendar-hover-p3tfTz/`.

## 2026-10-07 · Calendar weather/corners

Headline and Today use current weather together; older/future daily values remain
real. Forecast rows:Today100%,Yesterday/Tomorrow70%,two-day distance60%.
Three bottom controls now have7px corners.51 tests pass; active London weather,
native renderer/logs and [actual output](site/assets/calendar-native.png) verified.
Files:CalendarPanel.qml,weather.py,tests/test_weather.py,site catalogue/capture.
Recovery:`.local/backups/2026-10-07-calendar-iSxpER/`; unrelated settings preserved.

## 2026-10-07 · Outer margins / status icons

Rail outer gaps halved; inside spacing restored. Sidebar status icons/readout30%
smaller, right anchored; all three header buttons unchanged.50 tests pass;
native output/logs checked. [Rail](site/assets/rail-native.png) ·
[Sidebar status](site/assets/sidebar-status-native.png).

## 2026-10-07 · Full-width correction

Restored full rail width. Contents/fonts/icons/dividers shrink proportionally
in both axes, with left/center/right anchoring and common right-status vertical
centers.50 tests pass; active output/logs checked. [Screenshot](site/assets/rail-native.png).
Supersedes the previous whole-frame width shrink. Backup:
`.local/backups/2026-10-07-rail-width-HmeTXH/`.

## 2026-10-07 · Uniform rail correction

Entire rail now scales to90%, including fonts/icons/control spacing; centered
on screen,58px reserved height. Supersedes the padding-only implementation.
50 tests pass; active native output/logs checked. [Screenshot](site/assets/rail-native.png).
Source/live originals:`.local/backups/2026-10-07-rail-scale-icNARB/`.

## 2026-10-07 · Compact rail

10% less vertical space; unchanged type/icons/horizontal alignment. Active desktop
hot-reload and58px work-area reservation verified;50 backend/five website tests pass.
Files:Theme.qml,Rail.qml,Bar.qml,RailReservation.qml and the website rail asset/catalogue.
[Actual output](site/assets/rail-native.png) · [Website](https://dsksnkz.github.io/ghOSt/).
Recovery:`.local/backups/2026-10-07-rail-DjS5si/live/`; unrelated files preserved.

## 2026-10-04 · Website and descriptions

Short function/how descriptions; seven website views; minimal Settings changer
with fourteen pages; labeled sidebar/calendar motion and readable web helpers.
[Output and verification](docs/changes/2026-10-04-website.md) ·
[Settings screenshot](site/assets/website-settings.jpg) ·
[Mobile screenshot](site/assets/website-settings-mobile.jpg) ·
[Website](https://dsksnkz.github.io/ghOSt/).
Source prompt/design hashes verified unchanged; broader desktop work remains pending.
This explicitly requested website change does not replace desktop-first development.

## 2026-10-04 · Native performance and UI finish

GPU liquid waves, unchanged rounded silhouettes/software fallback; minute clocks,
cached geometry, fewer work-area queries, narrow-label fades and disabled/control
motion refinements are installed in the existing ghOSt desktop profile.
[Native calendar](docs/images/2026-10-04-performance/calendar-native.png) ·
[Rail](docs/images/2026-10-04-performance/rail-native.png) ·
[Settings controls](docs/images/2026-10-04-performance/settings-controls-native.png) ·
[Sidebar notification region](docs/images/2026-10-04-performance/sidebar-notifications-native.png) ·
[Files,50 tests, CPU measurement limits and recovery](docs/changes/2026-10-04-performance.md).
Latest direct request makes future building desktop-first; no separate visual
preview/site build after that correction. Source prompt/design hashes remain
f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d /9cc34c7e555a0cbfbff777d194a13ac3b799e6fe.
Broader Figma/lock/EQ/terminal/migration requests are not marked complete.

Published source `cd1de19`; all four native output images and the shader package
match GitHub blob hashes. Fresh committed-archive50 Python tests and JS checks
pass; native calendar/sidebar remain open. No preview-site UI/assets changed;
existing push-triggered repository CI is left intact.

## 2026-10-04 · Rail fullscreen behavior

Rail hides on its monitor's fullscreen workspace and returns afterward. Tested/deployed; user confirmed fullscreen works.48 Python tests and actual Qt transition/dismissal assertions pass. Previous six corrections remain deployed. [Native output](site/assets/rail-native.png) · [Verification/recovery](docs/changes/2026-10-04-fullscreen.md) · [Pages](https://dsksnkz.github.io/ghOSt/). No shortcut/autostart/game/session changes; broader prompt pending.

Published72b60e2; Pages37208796866 succeeded. Fresh archive installation/48 tests/Qt assertions pass; HTML/script/native output bytes match remotely. Owned previews closed; active ghOSt logs clean.

## 2026-10-04 · Settings, rail, notifications and sidebar dismissal

Implemented/deployed latest six corrections. [Settings selection](site/assets/settings-general.webp) · [Rail alignment](site/assets/rail-frame.webp) · [Empty sidebar](site/assets/sidebar-frame.webp) · [Notification popup](site/assets/notification-popup.webp) · [Calendar border](site/assets/calendar-frame.webp) · [Changes,48 tests, native checks and recovery](docs/changes/2026-10-04-dismissal.md) · [Pages](https://dsksnkz.github.io/ghOSt/). Actual isolated Qt Escape/pointer events pass; native focus/mask loading and a real incoming banner verified. Physical compositor event automation is not claimed. User prompt unchanged; broader revision still pending. Private native captures remain ignored, source/screenshot publication tracked below.

Published source61a00ea and website cache fix557c4e2; Pages run37207613146 succeeded. Fresh archive installation/48 tests/input assertions pass.26 changed assets match remotely; Notification popup visibly loads actual output. Only the known native test notification was removed afterward; no fake startup notice, legacy-owner takeover or private screenshot publication.

## 2026-10-04 · Rail, sidebar, Settings and calendar spacing

Implemented/deployed the latest eight corrections: clock spacing and right-icon alignment; root sidebar Escape;40% Settings glyphs with larger rows/groups; separate pencil gap; complete public runtime/installer/readable QML; larger calendar. [Actual output, tests and recovery](docs/changes/2026-10-04-spacing.md) · [Source](docs/source.md) · [Settings](site/assets/settings-general.webp) · [Calendar](site/assets/calendar-frame.webp) · [Pages](https://dsksnkz.github.io/ghOSt/).47 Python tests and fixture/native checks pass; no private native capture published. Full prompt remains pending for unrelated documented backlog.

Published UI/source `e6e06d6` and notification release-test correction `7311088`; Pages run37204033956 succeeded. Fresh tracked-archive installation and all47 tests pass; all30 changed public assets match local bytes and the public Settings image loads. User prompts/designs untouched; pending full revision retained. Keybindings/autostart/wallpaper and notification owner preserved.

## 2026-10-04 · Figma corner renderer corrected and live

Corrected actual outlines/clipping across rail/sidebar/calendar/Settings:15/11px cards,21px portraits,10px grey frames and8px icon wells. Editable Figma distinguishes0% card smoothing from60% Settings portrait/main frame; navigation selection is square. [Files, verification and remaining gaps](docs/changes/2026-10-04-corners.md) · [Sidebar](site/assets/sidebar-frame.webp) · [Settings](site/assets/settings-general.webp) · [Calendar](site/assets/calendar-frame.webp) · [Pages](https://dsksnkz.github.io/ghOSt/).45 Python tests, geometry/pixel checks and runtime regressions pass. Tested/deployed only requested ghOSt profile; shortcuts/autostart/wallpaper/legacy processes preserved. Prompt text unchanged; broader revision remains pending.

Published source976fbf0; Pages run37201326308 succeeded. All30 output/HTML/script/wallpaper assets byte-verified remotely; public Settings/Sidebar display new corners. No full-prompt completion claimed.

## 2026-10-04 · Desktop-visible corrections

Applied and deployed the requested rail/sidebar/calendar/Settings corrections. Added left rail hairlines and ghOSt notification history/backend; repaired a stale-focus transition that dismissed Settings. Grouped frames, picture chooser, PC-name editor, creator Info,15/11/21/10/8px G2 controls, larger statuses, randomized left-to-right entry and cylindrical workspace wheel are now in the installed ghOSt profile. Shortcuts, wallpaper, autostart and unrelated services preserved.

[Sidebar/history](site/assets/sidebar-frame.webp) · [Settings notifications](site/assets/settings-notifications.webp) · [Settings](site/assets/settings-general.webp) · [Rail](site/assets/rail-frame.webp) · [Composition](site/assets/desktop-frame.webp) · [Calendar](site/assets/calendar-frame.webp) · [Pages](https://dsksnkz.github.io/ghOSt/) · [Checks, recovery and remaining limits](docs/changes/2026-10-04-desktop.md).

Current GitHub/local prompt/design blobs match `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d` / `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`.45 Python tests plus native/fixture checks pass. History starts with ghOSt; observation cannot control another server's banners or action signals. Independent server actions/replacement/expiry/DND/dismissal tested on a private bus. Broader Figma parity, independent lock, embedded EQ and terminal/migration remain pending; the full revision is not marked completed.

Published source `a953a7e`; [Pages run37199503178](https://github.com/dsksnkz/ghOSt/actions/runs/37199503178) succeeded. Changed output and wallpaper bytes match remotely; public Sidebar preview loads, with390px layout checked for overflow.

## 2026-10-04 · Explicit Sunday workspace build

Built and isolated-tested the projected workspace wheel: curved depth/rotation, fixed triangle, smooth rapid retargeting, reduced motion and accumulated scrolling through empty 1–5/populated higher desktops. [Rail](site/assets/rail-frame.webp) · [Motion](site/assets/workspace-wheel-motion.webp) · [Composition](site/assets/desktop-frame.webp) · [Verification and remaining gaps](docs/changes/2026-10-04-workspace-wheel.md) · [Pages](https://dsksnkz.github.io/ghOSt/). Active desktop unchanged. Published source0b19c9e; Pages run37193540728 succeeded; static output bytes verified remotely. Same prompt/design blobs f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d / 9cc34c7e555a0cbfbff777d194a13ac3b799e6fe; full revision remains pending.

## 2026-10-04 — Settings groups, portraits, PC-name editor and Info

Published release `bcd8e3e`; Pages deployment37171957777 succeeded. Actual output links below are live, with every changed screenshot byte-verified. [Verification limits](docs/changes/2026-10-04-settings.md#publication).

Implemented original five-function frame plus separate added category frames; both picture-chooser controls/private immutable local copies; validated PC-name edit/Save/Cancel flow; measured pencil placement; exact `ghOSt - by you and Dsksnkz` creator Info. Added two-tone pencil SVG (61 icons). Reverified earlier local sidebar/calendar/rail corrections without activating them.

[Settings](site/assets/settings-general.webp) · [PC-name editor](site/assets/settings-name-editor.webp) · [Picture fixture](site/assets/settings-portrait-fixture.webp) · [Search](site/assets/settings-search-sound.webp) · [Composition](site/assets/desktop-frame.webp) · [Pages](https://dsksnkz.github.io/ghOSt/) · [Files, checks and remaining items](docs/changes/2026-10-04-settings.md).

GitHub prompts.md blob `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`; design blob `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe` matched local copies.41 Python tests,15 launcher assertions, isolated Settings/property/motion/capture checks and staging install passed. No live desktop, autostart, shortcut, wallpaper or hostname change. The same heartbeat is restored to five hours; weekday-only builds after this first 03:20 Sunday run. Pending: independent notifications/lock, 3D wheel, left rail dividers, native input/GPU/multi-monitor parity, embedded EQ and broader migration. This partial prompt revision is not marked completed.

## 2026-10-04 — sidebar, calendar and rail corrections staged

Implemented the requested left-to-right grouped sidebar entrances,15/11 px control radii, larger right-anchored status icons, calendar action corners, all-Nerd rail typography and centered stationary workspace triangle. [Actual output, checks and remaining requests](docs/changes/2026-10-04-small-corrections.md). Runtime geometry/font/motion checks,14 Settings pages, calendar animation checks,36 Python tests,15 launcher assertions and isolated staging installer passed. No active desktop/config/autostart changes; no publication. Independent notifications, Settings correction flows, 3D wheel and remaining Figma parity stay queued. The user prompt revision is not complete.

## 2026-10-03 — latest corrections queued, not implemented

Manual build stopped. Next scheduled start: **03:20 Europe/London, 2026-10-04**. [Saved corrections and unfinished state](docs/next-scheduled-corrections.md). Existing heartbeat is active, anchored to03:20 for its first run; that run restores the previous five-hour weekday workflow. No new UI screenshot, activation, commit or publication here. The preceding reference pass and its images remain local/unpublished and require corrections plus final verification. Prompt revision remains pending.

## 2026-10-03 — Desktop 1 and Settings reference pass

Measured both current Figma desktops; staged the original profile artwork, actual plain JetBrains Mono fonts/weights, compact Settings navigation/search/separators, sparse General composition, right-anchored sidebar statuses and three-button header, rail fill/dividers and 733 × 310 calendar. Preview Settings origin is (524,212). [Output and honest remaining gaps](docs/changes/2026-10-03-exact-figma.md) · [Settings](site/assets/settings-general.webp) · [Desktop 1](site/assets/desktop-frame.webp) · [Pages](https://dsksnkz.github.io/ghOSt/). Current pass is staging-only; active desktop is unchanged. Prompt/design blobs remain f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d / 9cc34c7e555a0cbfbff777d194a13ac3b799e6fe. Full 100% parity is not claimed and this prompt revision remains pending.

Latest result: [Settings, rail-autostart replacement and verified calendar/sidebar polish](docs/changes/2026-10-03-settings-polish.md). [Settings screenshot](site/assets/settings-general.webp). Earlier partial-state entries below are historical.

## 2026-10-03 — scheduled continuation checkpoint

Manual work stopped at the user's request; the weekday five-hour schedule was resumed with the latest corrections queued. [Pending implementation and verification](docs/pending-polish.md) includes staged G2 material, widened calendar, grouped sidebar motion/fades, workspace behavior and the new Figma Settings measurements. The rail work-area fix and full Settings app remain unfinished. No new screenshots/publication are claimed for this incomplete pass.

## 2026-10-03 — Figma dimensions, type and three-layer sidebar

Read the signed-in Figma's nested editable properties; applied the measured rail positions, full 733 × 310 calendar frame, sidebar off-screen origin, colors, outside/inside strokes, 7 px main radii, 15/11 px housing/well radii, type sizes and weights. Added Turret Road Regular/Medium, the solid calendar gear and corrected liquid-label contrast. The sidebar slides left-to-right, and its focus now coexists with the calendar. User-requested rail/calendar/sidebar are running; keybindings, wallpaper, old shell and autostart were preserved. London weather and real performance values remain live.

[Composition](site/assets/desktop-frame.webp) · [Calendar](site/assets/calendar-frame.webp) · [Sidebar](site/assets/sidebar-frame.webp) · [Rail](site/assets/rail-frame.webp) · [Pages preview](https://dsksnkz.github.io/ghOSt/). Public images are labeled actual-QML sample renders, not chat/nearby-network captures. [Exact measurements and limits](docs/figma-spec.md). Fifteen Python tests, fifteen launcher assertions, icon parity and calendar animation checks passed; live configuration loaded and both panels were visibly inspected together. Physical mouse automation, full notifications/Settings/lock, some raster-derived font details and the remaining legacy audit are still pending. Source prompt/design blobs: `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d` / `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`. This does not mark the complete prompt delivered.

2026-10-03: corrected live sidebar wiring (missing shell instance and menu-button target). Reload succeeded; the sidebar toggle now creates the visible ghost-sidebar layer. Left-to-right slide retained.

## 2026-10-03 — rail and whole calendar refinement, sidebar staged

The new annotated screenshots were used for the 7 px rail/calendar/sidebar outer frame rule, inner-radius calculation, 733 × 310 calendar ratio, three-position workspace wheel, rail grouping and left sidebar proportions. The live calendar and rail were revised under the user's earlier approval; the new sidebar is kept staged pending separate approval. London weather and real performance readings are connected. The preview verifies the 1.5-second randomized opening, weather-specific rain/lightning animation, liquid motion and reduced-motion behavior. Power opens a compact menu first and disruptive actions require another deliberate click; lock is shown as unavailable instead of calling the old rice.

Published screenshots: [calendar](site/assets/calendar-frame.webp), [rail](site/assets/rail-frame.webp), [sidebar with sample names](site/assets/sidebar-frame.webp), [power HUD](site/assets/power-frame.webp). [Live Pages preview](https://dsksnkz.github.io/ghOSt/) deployed from commit `b935b77`; the HTML and all four image URLs returned HTTP 200. The separate local live-sidebar capture contains nearby network names and was not uploaded. Fifteen Python tests, fifteen launcher assertions and the isolated animation check passed; native QML loaded, Hyprland config errors were empty, and bind JSON stayed byte-identical. Direct physical-click testing remains pending, so full prompt completion is not claimed. Source prompt and mainDesigns Git blob hashes: `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d` / `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`. See [change record](docs/changes/2026-10-03-frames.md) and docs/PROGRESS.md for remaining gaps.

## 2026-10-02 — whole calendar frame, local staging

Implemented/continued the supplied whole-frame composition and visible clock section of the top rail, not only the date grid. Includes weather illustration/forecast area, GPU/RAM/CPU liquid meters with clock switching, calendar navigation, bottom controls, randomized subframe reveal and reduced-motion handling. No rail hover text. No changes to the active desktop.

Local output: `.local/verification/calendar-evening/calendar-full-frame.png` (sample weather/metrics clearly labeled) and `calendar-real-readings.png` (real telemetry). Fifteen Python tests and fifteen launcher assertions pass; QML isolated loading and preview IPC behavior checked. Weather location is not configured; real weather is therefore unavailable. Power dispatch remains disabled; full Settings and native interactive validation remain pending. This is not a claim of complete prompt delivery or published output. See docs/PROGRESS.md.

## 2026-10-02 — standalone SVG icons

Completed the separately requested icon pack: 60 individual transparent SVGs, each in black and white, including common Settings categories, hardware, weather, media, navigation and session actions. [Download/preview](https://dsksnkz.github.io/ghOSt/icons.html) · [Usage](docs/icons.md) · [Verification](docs/changes/2026-10-02-svg-icons.md).

[QML output](site/assets/svg-icons-qml.png) · [Dark gallery](site/assets/svg-icons-web-dark.png) · [Light gallery](site/assets/svg-icons-web-light.png) · [Mobile](site/assets/svg-icons-web-mobile.png).

Read prompts.md at blob f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d and the mainDesigns calendar image at blob 9cc34c7e555a0cbfbff777d194a13ac3b799e6fe. Its calendar redesign is still pending; this does not mark that prompt completed. Terminal, rail tooltip removal, power HUD and previous-rice dependency removal also remain queued. No live activation or shortcut changes.
# 2026-10-03 / sidebar slide

The ghOSt sidebar now slides in from the left instead of fading in place. Live configuration reloaded; direct pointer verification remains pending. The active calendar, rail and keybindings were not changed.
# 2026-10-03 · Settings, rail, calendar and sidebar

Added fourteen-page Settings; continuous G2 corners; wider calendar; grouped sidebar entrances and long-name fades; stationary workspace indicator and soft power glow. The user explicitly requested replacing the old rail's autostart: ghOSt now starts from the existing start handler, the previous rail is disabled, and unrelated services/keybindings remain intact. Native transparent work-area reservation is verified at 64 px.

[Settings](site/assets/settings-general.webp) · [Sound](site/assets/settings-sound.webp) · [Battery](site/assets/settings-battery.webp) · [Calendar](site/assets/calendar-frame.webp) · [Sidebar](site/assets/sidebar-frame.webp) · [Composition](site/assets/desktop-frame.webp) · [All Pages previews](https://dsksnkz.github.io/ghOSt/) · [Verification and remaining items](docs/changes/2026-10-03-settings-polish.md).

36 Python tests, 15 launcher assertions, isolated Settings/sidebar/calendar checks and native load/layer/log checks pass. Published release `6c500a7`; Pages workflow `37155289952` succeeded and the live Settings image loaded. Source prompt blob `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`; mainDesigns blob `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`. Prompt still pending: exact portrait/unmeasured layers, embedded EQ, independent lock/notifications and broader migration. No fabricated history or disruptive test actions.
# 2026-10-09 / Serpantinum replacement — pending

Direct request: "yes, lock with wlogout, screenshots with hyprshot, and clipse".
Live Hyprshot region/output and Super+V Clipse bindings installed, backed up,
Lua-checked and reloaded without compositor errors. Clipse text/image watchers
running; no private history published. Existing screenshot edit combinations
now capture without editing (no installed swappy). No session or capture action
tested. Wlogout only opens a session menu; its existing lock command is hyprlock.
Actual locker choice/configuration and remaining shortcut migration must be
resolved before removing Serpantinum. Not marked complete or published.
# 2026-10-09 / Realistic Venetian blinds

Request: "it dosent look like blinds, it looks like straight bars. make it as realistic as possible. maximum details".

Implemented curved 3D thin-sheet slats, rounded ends, painted/brushed material,
lighting and cast shadows, paired ladder cords/rungs and head/bottom rails.
Shared procedural geometry avoids rebuilding meshes for every animation frame.
Preserved descent, typing blur, secure authentication policy and rotating exit.
Added a detailed software-renderer fallback. Installed only affected lock files
after safe tests; no actual lock or authentication invoked. Source/live paths
snapshotted in `.local/backups/2026-10-09-realistic-blinds-SaUciM/`.
Software and native Wayland/OpenGL visual/input/mock-auth checks and production
compile pass. Actual renders: `docs/images/2026-10-09-realistic-blinds/`.
Real authenticated unlock/handoff remains unverified; no parity claim.
# 2026-10-09 / Lock idle reset and performance

Request: "make it so if clicked outside, it dosent blur and if waited 10 seconds it cancels blur aswell, and fix lag issue, without letting me see while ur testing".

Outside clicks now leave closed blinds sharp, or dismiss an awake password/blur
view; Escape also dismisses. Idle for 10 seconds restores the blinds and clears
input. Activity resets timers across outputs; busy authentication pauses reset.
Reduced blur target to quarter pixels, shared slat material, reduced MSAA/shadow
quality and removed SSAO while preserving curved geometry and cast shadows.
Only offscreen testing performed, no visible test window or session lock. Tests
verify input/reset/clearing/busy policy and production types compile. Software
fallback images are recorded; offscreen 3D blank output is not visual evidence.
Native FPS/lag and actual unlock remain user-verification pending. Snapshot:
`.local/backups/2026-10-09-lock-idle/`. Installed affected ghOSt lock paths only.
# 2026-10-09 / Password glass and cursor-controlled blinds

Request: "make the password bar just an border with inside as blur, and the blinds is rotateable with cursor, not much though".

Removed opaque field fill; retained G2 border around a small cropped/blurred
backdrop sample, masked to the field corners. Cursor position drives smooth
±3-degree slat rotation, disabled during credential blur/reduced motion and
attenuated during exit. Secure lock/authentication policy and idle reset retained.
Offscreen tests verify bounds, transparent fill, first-key input, reset and
mock-auth; production types compile. GPU frosted blur/native 3D appearance not
visually tested because the user prohibits visible testing; software captures
are explicitly labelled. No lock, PAM or desktop-visible test window invoked.
Backup `.local/backups/2026-10-09-lock-glass/`; four ghOSt lock files deployed.
# 2026-10-09 / Cursor tilt cap and blur cancellation geometry

Request: "cap angle at 30, and the scale bugs abit when canceling blur".

Cursor tilt increased to ±30 degrees and smoothly attenuated with reveal.
Password field stays in layout until the column fade completes, without early
height/centering changes; hidden credentials cannot receive input. Backdrop
render target stays full-sized across blur toggles rather than resizing the
orthographic viewport. Retained prior shared materials/shadow optimizations.
Offscreen bounds, intermediate tilt, fixed layout, input/idle/mock-auth tests
and production compile pass. Software screenshot recorded; native visual
confirmation pending. No desktop-visible test window, real lock or PAM invoked.
Snapshot `.local/backups/2026-10-09-lock-tilt30/`; LockScene installed only.
# 2026-10-09 / Calendar background and weather stroke weight

Request: "remove the gradient of the calendar bar and set the weather icons to less weight icon".

Flat #151515 calendar background replaces gradient. Weather headline/list use
weather-only 1.25px strokes (previously 2px), same exact SVG geometry; animated
rain uses 1.2px drops. Other icon styles and calendar behavior unchanged.
Compile, input/weather and 16 weather tests pass; added icon geometry/parity
assertion. Offscreen component screenshot inspected; no visible testing window
or system action. Live files installed with reversible snapshot at
`.local/backups/2026-10-09-calendar-flat/`; clean screenshot recorded.
# 2026-10-10 / Serpantinum removal

Request: "uninstall every serpantinum thing, including this top bar wtf is it doing there behind my ghost bar".

Removed legacy autostart and command dependencies, preserved shortcut
combinations with native workspace actions and ghOSt counterparts. H/A now
Info/Widgets because old guide/autohide have no exact counterpart. Source,
configuration, state, runtime/caches and unused nested legacy-dependent shell
moved to private recoverable backup. No legacy processes or layers remain;
ghOSt is the sole shell and owns the now-vacant notification service legitimately.
Root command symlinks remain inert/dangling: administrator password required
for unlinking, so full uninstall is not marked complete. Lua/config/compile/IPC
and layer/reference checks pass. Rail crop published without private titles.
Backup `.local/backups/2026-10-10-serpantinum-removal/`; no auth/session tests.

# 2026-10-10 / Launcher terminal commands

Request: "make it possible in app launcher to put in terminal  commands".

Added explicit `>` command mode alongside unchanged application search. A
Run in terminal row executes only on Enter/click, through Kitty with Bash and
held output; quotes/pipes passed intact in a single argument. Empty commands
cannot run, command rows cannot be pinned, command strings are not persisted.
Node and Qt offscreen guard/dispatch tests pass along with existing input and
compile checks; no actual command executed in testing. Sample-only screenshot
published. Source/live files snapshotted, installed and named ghOSt reloaded.

# 2026-10-10 / Launcher screenshot composition

Request: "it runs in background, without showing terminal. also input resets everytime it opens. make it look like this:, with the selection bar animated moving up or down".

Implemented background Bash dispatch with no terminal, explicit > mode and
Enter/click guard. Fresh openings clear input. Rebuilt launcher around supplied
rounded search/outlined result composition: centered 600px frame, installed
application artwork, larger labels, no header/footer/count blocks, retained
hover pin controls and scroll. Selection outline animates both directions.
Qt offscreen reset/selection tests, Node ranking/argv, existing input and compile
checks pass; no commands executed during tests. Screenshots contain only Spotify
and harmless command text, published with source. Four live files deployed and
ghOSt reloaded, with reversible exact-path snapshots. Native command launch
remains user-verification pending. Earlier Kitty-command behavior superseded.

# 2026-10-10 / Smaller launcher and arrow-key selection

Request: "too big, scale it down so it can fit 1 more app while still having some space, scale down the  total size.  make it possible for up down arrow keys to control selection, and the selection isnt grey fill, its only a grey stroke. arrow keys selection is animated, smooth animation".

Launcher reduced to 480×384, four complete rows with bottom breathing room,
smaller icons/labels/search and no partially clipped fifth item. Explicit arrow
event handling drives smooth Bézier outline movement. Transparent selected row,
1px grey stroke, no hover fill. Offscreen real key-event/animation/geometry tests,
existing input/compile and Node checks pass; actual render recorded. Installed
two affected live files and reloaded ghOSt; backup retained. No test app/command
executed. Background command mode and fresh-open reset preserved.

# 2026-10-10 / Wider, flatter launcher

Clarification: "i mean wider and flatter" supersedes "make it flatter and smaller".
Changed launcher to 560×328, 48px rows/32px icons/44px search, retaining 18px
labels, four whole rows, bottom breathing room and animated stroke selection.
Offscreen keyboard/animation/geometry and compile pass; actual render inspected.
Two live files installed and named ghOSt reloaded with exact-path backups.

# 2026-10-10 / Smooth scrolling to lower launcher results

Request: "when it moves down to the down element, the scroll animation is not smooth".

Replaced immediate viewport positioning with coordinated 220ms Bézier scrolling
and outline movement. Stable index geometry avoids virtual-item jumps; repeated
keys retarget smoothly and direct pointer movement cancels keyboard animation.
Offscreen real keys verify intermediate scroll, synchronized outline, rapid
Down and reverse Up settlement; existing input/compile/Node checks pass.
Actual component screenshot recorded. One live file installed and ghOSt
reloaded, preserving size, stroke style, commands and fresh-open reset.

# 2026-10-10 / Escape closes launcher

Request: "if pressed escape it turns off, dont lemme see when ur testing".

Added explicit BeforeItem Escape handling, command/query clearing and close
signal wired to the live panel. Offscreen Qt key event verifies closure request
and no execution; compile/existing input checks pass. No visible testing or
actual command launched. No appearance change; prior screenshots still apply.
Two live files installed and named ghOSt reloaded; exact backups retained.

# 2026-10-10 / Super+A restored

Request: "why the fuck did you change my keybinds, super a back to zed not settings".
Restored live and public migration Super+A to zeditor. Earlier reassignment to
Widgets was incorrect; other bindings untouched. Lua/reload/configerrors checks
only, no visible test launch. Exact affected paths backed up and published.

# 2026-10-11 / Power Saver and shell controls

Request: "turn on power saver mode on the laptop and add buttons that control saver, normal and performance in the shell".

Activated existing system Power Saver from Balanced. Added Saver/Normal/
Performance to shell battery popup and Settings Battery, real observed selection,
busy/error handling and unavailable-performance guard. Normal maps to Balanced.
Existing service/CLI reused; no install, hardware/firmware/fan/game configuration
change. Offscreen buttons/preview isolation/passive live Saver observation,
compile and existing input checks pass. Test modes never switch live Normal or
Performance. Four live files installed and named ghOSt reloaded; Saver confirmed.
Exact affected paths backed up; profile prior state Balanced recorded. Actual
component screenshot published alongside code; other modes await user selection.

# 2026-10-17 / Desktop and code efficiency

Request: "hey im away, improve speed of code and desktop efficiency".

Inspected idle shell/processes, timers and existing source before changing code.
Cached launcher catalogue normalization, replaced repeated pin-array sorting
lookups with per-query Set membership, preserved native entries and exact order.
Disabled useless sidebar brightness timer wakeups on external monitors and
guarded overlapping reads. Saved-original comparison: 2,000 apps/400 pins/64
queries, five-trial medians 328.13ms vs 94.38ms (3.48× query microbenchmark,
not a desktop FPS claim). Node and real offscreen input/scroll/Escape/timer tests
and compile pass. Three live files installed; ghOSt reload and parity verified.
Unchanged-appearance screenshot recorded. No game, keybind, network, power-mode,
driver or visual changes. Current Balanced profile preserved; backups retained.

# 2026-10-24 / Font trial and modest weight reduction

Request: "change the font to a macos like font for everything, lets see how it looks and if it looks bad ill reverse it"

Correction: "some font weight is too high, not change the font weight to light but decrease by alittle"

Trial uses installed Adwaita Sans across ghOSt and desktop font defaults; no Apple
font/download/package install. Shared heavy weights reduced only 50 points,
regular text unchanged. Kept sizes, layout, motion and icons; terminal/code font
preferences untouched. Apps with custom typography may ignore defaults or need
reopening. Shell and desktop preferences have private recovery snapshots and a
guarded desktop restore script. Offscreen render/input, mock lock, launcher/rail,
workspace logic and 81 Python tests pass. Native ghOSt family/rail inspected;
source deployed and named instance reloaded. Safe captures and preview updated.

# 2026-10-24 / Publish necessary Hyprland configuration

Request: "update necessary hyprland config to github ghost"

Compared active integration with repository snippets. Added scoped rules and
portable autostart; updated screenshot/clipboard/workspace bindings and portable
lock paths. Exported rules match the active laptop exactly. Excluded private and
unrelated system settings; no active desktop files changed or reloaded. Added
integration guide and README/Pages links. Lua syntax, recording-only API tests,
duplicate-key/path/privacy guards and site tests pass. Fresh compositor setup was
not performed. Snapshot retains the edited source originals locally.

# 2026-10-24 / Slide-only launcher, behind the rail

Latest request: "make it smoother it looks very slow". Shortened launcher-only
reveal from 220ms OutCubic to 150ms OutQuad, reducing the slow finish. Preserved
other popup timing, full-size geometry, reduced motion and behind-rail placement.
Motion/input/compile tests and native geometry observation pass. Backed up and
deployed Panel/PanelMotion, reloaded named ghOSt. Existing captures remain accurate
for geometry; this is not a claimed frame-rate performance improvement.

Request: "super space app launcher animation should be the app launcher sliding from top to position without scale change"

Follow-up: "make it spawn behind the top rail"

Launcher now moves its full native window from above the screen to y=68 without
scaling/fading; frame stays full-size while loading. Runs below the rail while
other popup layers/animations and shortcuts stay unchanged. Existing duration,
curve and reduced motion retained. Offscreen render/input, launcher regression,
compile and 76 Python tests pass; native layers/geometry checked. Backups retained,
three files deployed and running ghOSt reloaded. Safe captures/Pages updated.

# 2026-10-23 / Dark Settings and visual top-bar editor

Requests: "change the settings to a darker theme, and add a function in applications where it lets the user control which elements exist in the top bar, including its location."

Latest correction: "not just like a list of stuff, make it like a preview of the top rail and use drag and stuff to change elements"

Darkened Settings; replaced the intermediate list editor with a real rail preview,
draggable group/ordering handles and Hidden tray in Applications. Explicit Apply
saves a validated layout, live rail reacts, Restore default recovers exact prior
geometry. Keybindings unchanged; agent did not apply a chosen layout. Real Qt
drag/key integration, backend persistence/validation, JS geometry, 76 Python tests
and existing input/compile/clock/site checks pass. Snapshots retained, six runtime
files deployed and native view inspected. Safe images and Pages views updated.

# 2026-10-23 / Wallpaper file chooser

Request: "the file previewer in the wallpaper switcher is very bad, its hard to tell between text and background color, and change it to dark theme. also make it preview the image in the file manager there"

Implemented a dark wallpaper folder/image browser, replacing only the native
wallpaper FileDialog. Thumbnails, large preview, folder/path/keyboard navigation,
clear text and explicit confirmation; Cancel/Escape never apply. Invalid images
cannot be confirmed. Actual Qt input/render tests, compile, routing, rail and 74
Python tests pass. Affected files backed up, deployed to existing ghOSt and opened
on the laptop; native appearance inspected. No live wallpaper change in tests.
Safe component render added to docs and the existing Pages Wallpaper view.

# 2026-10-23 / Nautilus

Request: "make nautilus use the folder icon pack you made. and change the theme so that the text dosent blend in to background, and its a dark theme."

Implemented the approved rounded-folder icon overlay and a Nautilus-scoped dark,
high-contrast stylesheet. Snapshot before applying; activated on the laptop and
opened Files. Actual isolated and live Nautilus inspected, tests and GTK4 parsing/
icon lookups pass. Other icon types inherit the previous theme. Icon preference
affects GTK folder icons across applications; palette remains scoped to Files.
Privacy-safe native image and recovery notes recorded in docs.

# 2026-10-17 / Readable source organization

Request: "ok make it better", following discussion of editable/readable code.

Focused readability pass: named launcher geometry/motion values, extracted reset
and scroll helpers, expanded dense functions, preserved cached search. Settings
catalogue/group geometry moved into a small independent JS module with pure unit
tests. Added `docs/CODE_MAP.md` so file ownership, generated assets, private files
and safe verification commands are discoverable. Exact saved-original navigation
data/layout comparison and existing Node/Qt/Settings/distribution/power-preview
tests pass. Four runtime files deployed; ghOSt reload clean. No design, animation
timing, bindings, system policy or game changes. Backups and clean render retained.
This improves the touched areas; it does not claim the entire repository has
been refactored or reviewed exhaustively.

# 2026-10-23 / Center contains only the clock

Request: "for top bar, only use the clock in the center, remove all other. as in the center only clock".

Removed date/weather/divider from center section, centered clock itself exactly.
Preserved left/right rail content, clock typography and calendar-opening action.
Offscreen centering at two widths and actual click checks pass, alongside compile
and input checks. Capture has no private session/MPRIS data; Pages rail image
updated. Only Rail deployed; named ghOSt reloaded and backups preserved.

# 2026-10-24 / Material icon pack and blur correction

Requests: "use google material icons then, and if successful update to github"
and "some icons just look really blurry fix".

Replaced shared ghOSt control SVGs with official Google Material Symbols Outlined,
kept lighter weather and the G wordmark, regenerated Files folder overlay. Added
offline reproducible generation, source hashes and Apache notices. Fixed live
reload image caching and increased cached raster resolution for scaled small
icons (2×, minimum48px, mipmaps), without resizing controls or changing spacing.
Tested rendering, source hashes, real Qt scaled sampling, dismissal/input and
Settings pages; deployed exact icons/SvgIcon and folder files, named ghOSt reload
clean and native output inspected. Safe component crops updated in Pages.
External standalone launcher/app logos are not part of this shared asset pack.
Verification, backups and publication scope: docs/changes/2026-10-24-material-icons.md.

