# 2026-10-04 — sidebar, calendar and rail corrections

Manual continuation authorized by “do some now.” Source-only, isolated staging; no live deployment or publication. Latest direct corrections override older Figma typography choices. GitHub prompts.md and mainDesigns were read and matched local blob hashes `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d` and `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`.

## Implemented locally

- Sidebar item groups now enter from the left and settle at their original coordinates, retaining randomized order and whole WLAN/Bluetooth cards. Outer slide/reduced-motion handling retained.
- Header buttons, sliders and notification housing share a 15px radius. WLAN/Bluetooth housing15px and inner11px are retained; list interaction backgrounds now also use11px. Slider-fill clipping follows the same radius/inset as its track instead of the old semicircular ends.
- Right-anchored sidebar status group is136×26 with22px Wi-Fi/Bluetooth,30×26 battery glyph and14px battery text. Statuses vertically center together; the right edge remains21px from the panel edge. Power glyph centered precisely in its button.
- All three calendar action controls request15px radius; liquid benchmark corners retain15px. Existing24px small button geometry is preserved: normal renderer clamping limits effective radii to12px on those buttons. No false claim of a15px effective radius on a24px shape.
- Every rendered rail label now uses JetBrainsMono Nerd Font Mono. Date width increased to49px for the wider five-character monospaced date. Workspace numbers centered in23px cells; stationary triangle centered beneath the middle cell instead of offset left.

Files: `SidebarFigmaBody.qml`, `CalendarPanel.qml`, `Rail.qml`, `Workspaces.qml`; isolated preview inspection in `preview.qml`; regression checks in `scripts/verify_polish.py`. Previous dirty changes were retained, not reset.

## Verification

Cold isolated Quickshell fixture loaded without QML errors. Runtime inspection checked all rail font families, actual15/11px control properties, negative entrance offsets and zero settled offsets. Fourteen Settings page/geometry checks, sidebar randomized grouping/long-name captures, calendar ratio/reveal/rain/storm/reduced-motion/closed-state tests,36 Python tests,15 launcher assertions and whitespace checks passed. Default isolated staging installer succeeded.

Actual1920×1080 QML fixture captures reviewed:

- [Composition](../../.local/verification/2026-10-04-small-corrections/output/desktop-frame.png)
- [Sidebar](../../.local/verification/2026-10-04-small-corrections/output/sidebar-frame.png)
- [Long-name fade](../../.local/verification/2026-10-04-small-corrections/output/sidebar-long-names.png)
- [Calendar](../../.local/verification/2026-10-04-small-corrections/output/calendar-frame.png)
- [Rail](../../.local/verification/2026-10-04-small-corrections/output/rail-frame.png)

Sample data is visibly labeled. No nearby network names or desktop chat exposed. Offscreen checks do not prove native Wayland pointer interaction or GPU-render parity. The hot-reload preview briefly rejected IPC; it was cold-restarted and all checks above passed against the fresh instance. Only this run's own isolated preview was stopped afterward; active desktop processes/configuration, binds, wallpaper and autostart were untouched.

Snapshot: `.local/backups/2026-10-04-small-corrections/`. Independent notifications, Settings grouping/PFP/name flows/creator Info,3D workspace wheel, rail left dividers and remaining exact-reference details still pending. New local source and screenshots are not committed/pushed or reflected in live Pages; carry publication and remaining requests forward without marking prompts.md complete.
