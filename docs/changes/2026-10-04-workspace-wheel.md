# 2026-10-04 · Workspace wheel

Directly requested Sunday build. Staged implementation, not live activation.

## Changes

- Replaced the digit-swap translation with a 320 ms cylindrical projection: curved travel, depth-dependent scale/height/ink, restrained Y-axis rotation and edge fading. Five cached labels support seamless three-position wraparound.
- Kept the triangle and keyboard/pointer hit targets stationary. Retargeting starts from the current fractional pose, not a new settled digit. Reduced motion cancels the turn and snaps to its destination.
- Unified visible neighbors with the eligible workspace ring: empty 1–5, then populated higher desktops. A manually opened empty higher desktop remains visible but is not a scroll destination. No shortcut changed.
- Accumulated partial wheel notches instead of rounding every event; multiple notches retain their direction and count. Gaps between controls also accept scrolling. Native dispatch still uses the independently implemented serialized helper.
- Published actual frame captures and a compact animated WebP of the native QML fixture, including the final 5-to-1 turn for a closed loop. The website selects a still image when reduced motion is requested.

Files: `Workspaces.qml`, `WorkspaceWheel.js`, `Rail.qml`, `preview.qml`, `tests/test_workspace_wheel.cjs`, `scripts/verify_workspace_wheel.py`, README, site and these progress records.

## Reference and verification

Read the current editable Figma rail: node `1:4`, origin (19,16), 1882 × 46, fill #191919, radius 7, outside stroke 1/#4D4D4D. Workspace group `1:14` is (151,26), 99 × 27; white and #B8B8B8 numbers, #AEAEAE indicator. Retained the existing measured settled 0/36/76 px label origins and 15/11 px visual sizes, with the latest user-requested Nerd family. The depth/motion interpolation is independently implemented behavior, not a claim of pixel-perfect font raster parity. The Figma credit was accidentally nudged during keyboard navigation and immediately undone; its X was confirmed restored to 1094 before leaving that selection.

Default-branch `prompts.md` still matches local blob `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`; mainDesigns screenshot matches `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`, and `mainDesigns/1` matches `8b137891791fe96927ad78e64b0aad7bded08bdc`. User text unchanged; whole prompt remains pending.

41 Python tests, 15 launcher assertions and deterministic JS projection/ring tests pass. Actual isolated QML checks cover transient rotation/depth, fixed triangle, forward/reverse wrap, partial/multiple notches, populated higher desktops, exit from empty higher desktops, mid-turn retargeting and immediate reduced-motion response. Prior Settings (14 pages and portrait/name/search flows), rail/sidebar geometry/fonts and calendar weather/reveal checks pass. Default isolated installer succeeds. Cold fixture runtime has only the expected unset-Hyprland/window-mask warnings; offscreen hot reload was not IPC-ready, so only the exact owned test processes were restarted.

The non-fixture workspace component also cold-loaded offscreen without a QML component error; its live compositor connection was intentionally absent. Native population uses the [documented workspace toplevel model](https://quickshell.org/docs/v0.2.0/types/Quickshell.Hyprland/HyprlandWorkspace/), not stale IPC window-count snapshots. Local browser loaded the animated 960 × 210 asset; the 390 px responsive view had no horizontal overflow and its image fit the available width. Reduced-motion selection is implemented; browser media-preference switching was not automated.

No desktop/session action, active configuration, shortcut, autostart, wallpaper or existing shell process was changed. Keybind file SHA-256 remains `c0ade5d4f7a9706be56bf3a0a4257058bf1255e1dcb4ce47f71a109b8844b261`; autostart remains `5bd6cd0221940204352b5103dfc046ad2f7385199ad43ab8c31fcf033b8a75b6`. Live Hyprland error list is empty. The current wallpaper path still resolves to `flow 7.jpg`; the existing separately exported site background is preserved. No private SSIDs, chat or profile pictures appear in the captures.

## Output and remaining work

[Rail](../../site/assets/rail-frame.webp) · [Composition](../../site/assets/desktop-frame.webp) · [Motion](../../site/assets/workspace-wheel-motion.webp) · [Still](../../site/assets/workspace-wheel-still.webp) · [Live preview](https://dsksnkz.github.io/ghOSt/).

Local evidence: `.local/verification/2026-10-04-wheel/`; reversible snapshots: `.local/backups/2026-10-04-wheel/`. Restore the snapshotted project components if needed; `WorkspaceWheel.js` and the new test script can remain unused. This update does not require a live restore.

Pending: native physical input/GPU rendering/multi-monitor validation; measured left rail divider/alignment pass; independent notifications/lock; embedded equalizer; remaining Figma raster/image transforms and wider migration. No 100% parity or full-prompt completion claim.

Publication: source release `0b19c9e17310b94375425a5c3cd8440c745bfa2d` pushed; [Pages run 37193540728](https://github.com/dsksnkz/ghOSt/actions/runs/37193540728) succeeded. The live HTML includes the new wheel preview; remotely fetched rail/composition/still images match local SHA-256 bytes. The follow-up export closes the motion loop without changing the native component or static screenshots. Local desktop and 390 px browser previews loaded the animation and had no horizontal overflow. No whole-prompt completion or live activation is implied.
