# 2026-10-04 · Settings selection, rail alignment and notifications

Latest six direct corrections override previous square navigation selection and server-only banner choices.

## Changes

- Selected Settings navigation housing now10px radius with60% smoothing; existing8px icon wells and40% glyphs retained.
- Rail clock/calendar and battery text/icon share optical centerlines. `InkLabel.qml` uses the current font's tight glyph bounds rather than asymmetric line-box ascent/descent; spacing and Nerd typography retained.
- A360px top-centered ghOSt notification popup opens for real incoming notices in both independent-server and occupied-owner observation modes. It reveals quickly, expires, opens the sidebar when clicked and has a close control. DND suppresses ghOSt's own popup. No service takeover: another server may still show its own banner.
- Empty sidebar notification center contains only “No more messages”; removed the notification-like header and empty-state icon. Real messages and dismissal remain functional; no fake message is inserted at startup.
- Sidebar requests keyboard focus on opening, so Escape does not depend on clicking it first. A transparent temporary outside-pointer surface uses cutouts for rail/sidebar/calendar/other panels/banner and closes on mouse/touch input. It disappears on closure and reserves no work area. Sidebar no longer relies on a focus grab that can compete with the existing shell.
- Native calendar now explicitly paints its1px `#474747` grey outline;7px outer corner and820×347 composition retained.

## Verification and limits

48 Python tests pass, including notification server/observer/popup/DND/owner preservation, history, Settings and complete isolated installation. Real Qt Escape and pointer events reach the same sidebar/dismissal widgets in the offscreen input entry. Runtime spacing checks compare optical clock/calendar and battery/icon centers.14 Settings pages/flows, sidebar motion, calendar/weather/reduced motion and JS regressions pass. A capture pass was initially run during a motion test; its reduced-motion change invalidated that motion assertion. Checks were rerun serially with normal motion and pass. Unsupported offscreen PanelWindow validation was not treated as success; native loading verifies those types.

Tested/deployed only ghOSt. Native logs have no QML errors, notification observer ready, and an actual standard-protocol test notice mapped the new360×96 banner atx780/y76. Removed only that test record afterward. Existing notification owner`:1.19` and legacyPID1824 preserved. Native sidebar and temporary pointer-mask surface mapped at356×794 and1920×1080; calendar and sidebar inspected privately. Physical compositor click/Escape automation remains unverified: Qt events and native focus/mask configuration are not a claim that the user's physical input was exercised. No keyboard shortcut, autostart, wallpaper, hostname or session/power action changed; Hyprland config errors empty.

## Output and recovery

[Settings](../../site/assets/settings-general.webp) · [Rail](../../site/assets/rail-frame.webp) · [Empty sidebar](../../site/assets/sidebar-frame.webp) · [Calendar](../../site/assets/calendar-frame.webp) · [Notification popup](../../site/assets/notification-popup.webp) · [Pages](https://dsksnkz.github.io/ghOSt/).

Published images are actual isolated QML output with labeled samples;17 Settings and6 surface screenshots refreshed. Native captures with private browsing/network names remain ignored. Inspected live wallpaper path through its running service; independently exported its unchanged `flow 7.jpg` as1920×1080 WebP without private metadata. Originals preserved.

Snapshot of exact project/live/site paths: `.local/backups/2026-10-04-dismissal-VpleYp/`. Restore affected `live/` files and restart only ghOSt to roll back. Added input/capture/export scripts and reusable banner/glyph/dismissal components; the complete profile is installer-distributed. Unrelated untracked files preserved. Prompt/design blobs still match`f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d` / `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`; user text untouched. Full broader prompt remains pending for documented unrelated gaps.

Pointer mask uses the standard [Quickshell Region subtraction API](https://quickshell.org/docs/v0.2.1/types/Quickshell/Region/); keyboard focus follows [WlrKeyboardFocus](https://quickshell.org/docs/v0.2.1/types/Quickshell.Wayland/WlrKeyboardFocus/). No authentication or secure-lock behavior is implied.

## Publication

Source `61a00ea5081540c3e2263cd128d44da27f9691e9` pushed to main; a fresh tracked Git archive installs the complete profile and passes48 Python tests plus actual Qt input-event assertions. Preview inspection caught a cached older script that did not recognize the new notification button. Versioned script/image URLs in `557c4e2` fix this; [Pages run37207613146](https://github.com/dsksnkz/ghOSt/actions/runs/37207613146) succeeded. All26 changed public HTML/script/wallpaper/output assets match local bytes; the public Notification popup selection visibly loads1920px actual output. Browser proof saved privately with verification. Owned fixture/tab closed; desktop panels returned to closed state, rail active and menus available. No fake test message remains in the sidebar.
