# Animation smoothness pass — 25 October 2026

User: "still jittery, feels low on fps. also review all animations in this
desktop for ghOSt, and smooth out all animations to at least 60fps".

## Findings

- Display: HDMI-A-1 at 200 Hz on the NVIDIA GPU. Qt uses the threaded render
  loop with a 5 ms vsync animation driver and renders on the Intel iGPU. A
  separate 4 × 4 probe measured ~170 fps on Intel. Forcing NVIDIA EGL locked
  it to ~62 fps, so the GPU selection was left unchanged.
- Hyprland already has `no_anim` for ghOSt layers; no doubled animation.
- Live measurement (`bar frameStart` / `frameStop`, see below): in motion
  every surface already ran at ~200 fps (5.1 ms ticks). The jank came from one or
  two long frames right when an animation started, while the window mapped and
  built its page: media 27 + 20 ms, launcher 35 + 22 ms, calendar 33 ms,
  sidebar 64 ms open / 68 ms close, sound 16 + 22 ms; OSD 11 ms. The animation
  clock ran through them, so the first 30–60 ms of travel never drew.
- Only the launcher still moved its window every frame (layer margin, whole
  pixels), the same cause as the earlier media jitter.

## Changes

- `RevealGate.qml`: a surface's `reveal` follows its open state only after at
  least 6 ticks and then two consecutive frames under 9 ms (maximum 120 ms
  wait). The heavy setup frames then happen while the surface is still hidden
  (or still fully open, on close). Reduced motion stays immediate.
  Used by `Panel.qml` (all popups), `CalendarWindow.qml`, `Sidebar.qml`,
  `NotificationToast.qml`. The OSD is not gated, so volume feedback stays instant.
- Launcher now uses the still-window content slide (`PanelMotion` lead and
  `slideOffset`) like the media popup. Durations and easing are unchanged.
- Calendar subframe reveal and telemetry start with the gated motion. Sampling
  processes start 300 ms later (`serviceStart`), after the 260 ms frame reveal.
- `FrameProbe.qml` + `bar frameStart` / `bar frameStop` IPC: read-only
  frame-pacing diagnostics, idle unless armed.

No animation durations or curves were changed (per CODE_MAP: do not change
timing as a substitute for fixing computation).

## Verification

- After the gate (deployed, one clean reload): media, launcher, sound and
  sidebar show their long frames before the motion and an unbroken ~5 ms run
  during it. The calendar still had a 50 ms frame two ticks after the gate opened,
  consistent with process spawning at that moment; the `serviceStart` deferral
  addresses it.
- Launcher motion test updated for the still window; motion, compile, input,
  rail, calendar IPC and 83 Python tests pass.
- **Pending:** the calendar deferral (`CalendarPanel.qml`) is in source only.
  CS2 started before it could be deployed, and the post-fix calendar
  measurement was not taken. Deploy it when safe, then run
  `.local/verification/2026-10-25-animation-pass/measure.sh`. Nobody has
  watched the animations on screen. Late long ticks in "idle"/"close"
  rows are the probe's timer while no window draws, not jank.

Evidence: `.local/verification/2026-10-25-animation-pass/frames-{before,after}.txt`.
Snapshot: `.local/backups/2026-10-25-animation-pass/`.
