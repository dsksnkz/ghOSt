prompts outputs here

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
