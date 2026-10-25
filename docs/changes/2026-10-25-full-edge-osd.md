# Full-height, pointer-aligned edge volume OSD

Status: source implementation and pure logic tests complete; live deployment,
native verification and new screenshots intentionally pending while CS2 runs.
This latest direct correction supersedes the old middle-only edge/dead-zone design.

## Changes

- `EdgeVolume.bounds()` now covers the complete monitor height, starting at0.
  Left and right targets remain only2px wide, with no keyboard grab or sidebar action.
- Edge hover/click/wheel supplies screen-local pointer Y to `OsdState.show()`.
- `Osd.qml` positions its310px window with its center at pointer Y. Near top/bottom
  it clamps to screen bounds. Keyboard/non-pointer calls keep centered placement.
- Moving along an open edge updates placement;16ms coalescing bounds compositor
  reposition requests, rather than issuing one per high-rate mouse event. No
  timer runs when idle, and no pointer-motion subprocess is introduced.
- The OSD slider does not chase its own drag pointer. Volume changes remain
  explicit scroll/touch/drag actions; hover alone does not change audio volume.
- Existing fullscreen suppression stays enabled, protecting game input edges.
- Intro help and native test expectations now describe full-height behavior.

## Verification and gaming boundary

Low-priority Node tests pass for multiple screen heights, full edge coverage,
pointer-aligned centers, top/bottom clamping, invalid/missing pointer fallback,
small-screen bounds and bounded volume steps. `git diff --check` passes.

Before the latest full-height request, the first pointer-position implementation
was deployed and compiled/input-tested. Native pointer tests did NOT pass:
synthetic absolute input was not reliably at the requested coordinates. Do not
treat those attempts as evidence of correct native placement. Helpers exited;
no offscreen test instance or native test loop remains running.

After the user requested background work during CS2, only source edits and the
small low-priority JS test were performed. No live file copy/reload, new window,
capture, pointer move, volume adjustment, heavy regression suite or change to
CS2/Steam/background applications. The native helper now refuses execution while
a `cs2` process exists. A resource snapshot showed substantial game/background
load and swap use, but no benchmark established the cause of lag; this change
does not claim a measured system-wide performance improvement.

Once gaming has finished and activation is appropriate, compile the updated
surfaces, snapshot current live affected files again, deploy only EdgeHandle,
EdgeVolume, Osd, OsdState, shell and IntroTopics, then reload named ghOSt once.
Verify top/middle/bottom on both edges using actual compositor pointer positions,
plus clamping, unchanged volume, expiry and fullscreen suppression. Capture safe
OSD output then; do not mark the request fully completed before that verification.

Snapshots: `.local/backups/2026-10-25-pointer-osd/{project,live}/` retains the
initial originals. `.local/backups/2026-10-25-full-edge/project/` retains the
interrupted pointer-only revision before this full-height correction. Preserve
unrelated dirty work. Current prompt/mainDesigns hashes remain unchanged from
the inspected authoritative reference; the direct correction overrides old geometry.
