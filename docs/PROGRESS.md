# ghOSt progress

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
