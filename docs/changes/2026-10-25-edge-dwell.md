# Half-second edge dwell and fixed-position OSD

Latest correction: user reduced dwell to **200ms (0.2s)**. That delay supersedes
the original500ms implementation below; all latch/exit behavior is unchanged.
Updated headless production timer tests pass. Only EdgeHold/IntroTopics were
deployed; snapshot `.local/backups/2026-10-25-edge-200ms/{project,live}/`.

Latest instruction supersedes the earlier pointer-following design. Both screen
edges remain full-height and2px wide; existing fullscreen suppression remains.

## Behavior

1. Enter either edge and remain there for500ms. Leaving sooner cancels the timer.
   Moving vertically while waiting does not restart dwell.
2. At activation, capture the pointer's screen-local Y. Position the OSD there,
   clamped to screen bounds, preserving its current size and entrance animation.
3. Keep it fixed and visible while the pointer stays on that edge. No vertical
   tracking or periodic keepalive. Audio changes do not change its captured origin.
4. Leaving releases the edge-owned OSD and starts its normal close animation.
   Reentering needs a fresh500ms dwell and captures a new position.

Clicking/scrolling before activation cannot bypass dwell. Once active, scroll
adjusts volume in2% steps. Hover never changes volume. Edge-owned OSD does not
expire after2.2s; keyboard/non-edge OSD retains its normal timeout and touch/drag
slider. Edge mode intentionally closes when leaving the2px edge, so crossing
towards its card also closes it, following the latest explicit exit behavior.

## Files

- `EdgeHold.qml`: nonvisual dwell/latch/timer component, separately testable.
- `EdgeHandle.qml`: binds hover/visibility and latest pointer Y to that controller;
  activates/releases shared OSD and gates wheel input. Removed motion updates.
- `OsdState.qml`: edge ownership, fixed origin, hold/release and expiry separation.
- `shell.qml`/`qmldir`: registration and read-only `edgeHeld` diagnostics.
- `IntroTopics.js` and `docs/intro.md`: corrected user instructions.
- `scripts/verify_native_edge.py`: future native expectations updated; still
  opt-in and refuses during CS2 or fullscreen. Not run for this pass.

## Verification

`nice -n19 python3 scripts/verify_edge_hold.py` passed. It runs production EdgeHold
and OsdState against fake Desk/Settings singletons, disconnected from the session
bus, with no windows or cursor/audio/system actions. Actual Qt timers verify:

-500ms configuration, no opening before dwell, cancellation on short visits;
-position captured at dwell completion, not initial entry;
-no reposition on movement or repeated same-edge activation;
-remaining visible past2.2s and through a fake audio callback;
-wrong-edge release ignored, correct exit closes, reentry captures a new Y;
-ordinary non-edge OSD still expires normally.

Pure JS geometry/volume/search checks and production surface compilation also
pass at low priority. No full repeated regression suite, screenshots, physical
pointer movement or actual volume change was performed while the user is gaming.
Native physical-input/capture verification remains pending rather than claimed.

Six runtime files were copied in one batch, yielding one automatic reload:
`2026-10-25 08:52:05.704 Reloading configuration` → `08:52:05.914 Configuration Loaded`.
Read-only IPC returns `edgeHeld:false` and full-height edge bounds while idle.
No manual reload, game/app/service/network/keybinding/wallpaper/geometry change.

## Recovery

Exact affected project/live originals:
`.local/backups/2026-10-25-edge-dwell/{project,live}/`.
`EdgeHold.qml` is new; restore prior EdgeHandle/OsdState/shell/qmldir/IntroTopics
together if rolling back. Preserve unrelated edits. References remain unchanged
from verified remote prompt/mainDesigns blobs; latest direct behavior takes priority.
