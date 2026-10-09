prompts outputs here

## 2026-10-09 · Shaded, layered folder

Added the requested 3D-like grey shading with a dark rear/tab and lighter middle
front, rounded layers, rim lighting and a soft shadow. Standalone transparent
SVG/512px PNG are in `assets/folder-layered.*`; flat variants remain intact.
Small/large raster checks pass and output inspected. No Nautilus activation.
All 64 Python tests and flat-pack generator checks pass. Publication pending.

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
