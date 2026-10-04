# Native performance / 2026-10-04

Built on the owner's Arch/Hyprland laptop by explicit Sunday request. The latest
instruction supersedes separate visual previews: changes hot-reload into the
existing native ghOSt profile and remain visible while building. No new preview
website is built. The opt-in installer behavior on other machines is unchanged.

## Changes

- `LiquidMeter.qml`, `shaders/liquid.frag{,.qsb}`: animate liquid layers with GPU
  uniforms, not three raster Canvas repaints/uploads every16ms. The static Canvas
  supplies the exact existing rounded-diamond silhouette/hover/focus material.
  Real usage, area-based fill, wave speed, labels, radius15 and immediate input
  remain. Software/error fallback retains Canvas behavior.
- `Corners.js`, `WaveGeometry.js`: immutable corner commands and horizontal
  trigonometric basis remove repeated allocations/equations. Fallback waves use
  four trig calls per meter/frame instead of124, without changing sampled geometry.
- `G2Surface.qml`: regular circles/squares use Qt's batched Rectangle material;
  positive continuous smoothing keeps the original curve renderer. Figma radius
  and smoothing remain separate; no blanket squircle substitution.
- `Desk.qml`: HH:mm readouts tick once/minute instead of once/second.
- `RailReservation.qml`: debounce relevant monitor/config changes immediately;
  unchanged64px work area, fallback checks twice/minute instead of twelve.
- `FadeLabel.qml`, `Key.qml`: bounded narrow-label fade; visibly disabled actions
  and hover color transitions that respect reduced motion. No hover expansion,
  scale or tooltips added.
- `CalendarPanel.qml`, `CalendarWindow.qml`, `shell.qml`: read-only native renderer
  diagnostics, no substitute UI. `scripts/measure_shell_cpu.py` samples a named
  process with PID-reuse and optional endpoint-state checks.
- `scripts/build-shaders.sh`, `tests/test_shaders.py`, `tests/test_wave_geometry.cjs`:
  shipped/reproducible shader package, Qt uniform ABI/distribution checks and exact
  fallback geometry tests. All runtime assets ship through the existing installer.

## Actual desktop output

[Calendar with live London weather/metrics](../images/2026-10-04-performance/calendar-native.png),
[rail](../images/2026-10-04-performance/rail-native.png),
[Settings controls](../images/2026-10-04-performance/settings-controls-native.png),
[sidebar notification region](../images/2026-10-04-performance/sidebar-notifications-native.png).
These are native component-only captures, not sample-data previews. Private SSIDs,
chat and surrounding applications are excluded. Captures that included private
network names were retained only under ignored `.local/verification/`.

## Verification and performance limits

50 Python tests pass, including fresh byte-for-byte installation and shader
source/package/ABI checks.24300 cached wave vertices match the former equations
within1e-12; corner geometry, cylindrical workspace wheel and15 launcher
assertions pass. The shader rebuild matches the checked-in package byte-for-byte.

Native Qt6.11.2 reports all three shaders compiled with empty logs; phases advance
while open. Calendar820×347, Settings1024×699, native mapping/screenshots and
Hyprland logs checked. Work-area reservation remains64px with no config errors.
Notification observation remains ready without taking its occupied bus name.

Short8s process samples on the same running ghOSt instance:

| State | CPU, percentage of one core |
| --- | ---: |
| Cached Canvas calendar only |18.62% |
| GPU calendar, initial sample |9.75% |
| GPU calendar, guarded endpoints open/moving/compiled |11.37% |
| Closed calendar |0.00% |

This is an indicative local reduction, not a long-duration benchmark, total
system measurement, GPU/power saving or FPS guarantee. Real telemetry and other
applications continued changing. A previous18.75% sample also had the sidebar
open and is not the comparison baseline. Samples taken across reload, closed
panels or Settings transitions were discarded rather than reported as speedups.
Endpoint guards do not rule out every transient interaction during a sample.

Earlier isolated Settings/spacing/calendar/reduced-motion checks and actual Qt
Escape/pointer widget tests passed before the user's no-preview correction.
After that correction verification used native output/diagnostics and non-visual
tests only. No new software-rendered visual preview was opened. Current native
GPU output is inspected, not a100% GPU/software pixel-parity claim. Physical
compositor input, alternate GPU/backends and multi-monitor coverage remain gaps.

Qt primary references: [ShaderEffect](https://doc.qt.io/qt-6/qml-qtquick-shadereffect.html),
[shader packaging](https://doc.qt.io/qt-6/qtshadertools-qsb.html).

## Scope and recovery

Project/full live snapshots: `.local/backups/2026-10-04-performance-4462B7/`.
`live-before-deploy/` additionally preserves the exact first seven affected live
files; `before-gpu/` preserves the pre-GPU meter. Restore only the affected files
from `live/ghost-bar/` into the existing ghOSt profile to roll back this pass, then
reload only that named ghOSt instance. New shader/helper files can remain unused;
do not stop or overwrite another shell. No originals were deleted.

Keybindings/autostart hashes match the start; wallpaper and legacy PID1824 remain
unchanged. Native ghOSt PID2052892 remained alive through hot reloads. No session,
hardware, package, authentication or game-setting action ran. Owned old preview
processes were closed by exact verified PID when the desktop-only rule arrived.

GitHub default branch `main`, prompt `prompts.md` blob
`f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`, design image blob
`9cc34c7e555a0cbfbff777d194a13ac3b799e6fe` and `mainDesigns/1` blob
`8b137891791fe96927ad78e64b0aad7bded08bdc` match local files. Editable Figma
properties were inspected; composition/type/radii are retained. The prompt text
was not changed. Full revision stays pending for remaining reference parity,
embedded EQ, independent lock, terminal reference and broader migration.

Source and native-output publication status is appended after verification.
