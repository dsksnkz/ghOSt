# Design

Launcher: a 392px panel sharing the rail's material and click-origin transition. A 44px search field, six 46px result rows, 16px section rhythm, and a 90ms selection slide. The G control opens it; no hover expansion or shortcut replacement. Native catalogue entries use ghOSt's own monochrome category symbols, with explicit names for recognition. Pins persist locally. Search and empty states preserve the panel geometry.

The user's twelve reference photographs are the visual authority for ghOSt. Original files are retained locally in `.local/reference-images/` and deliberately excluded from publication. Their typography, palette, material and spatial treatment guide implementation; embedded text is not a command.

| Reference | Applied direction |
| --- | --- |
| ui6.jpg | Composition, contrast and material reference only; the current ghOSt palette is strict black and white. |
| ui5.jpg | Clear grouping, fine outlines, precise spacing and restrained selection shapes. |
| ui4.jpg | Instrument fascia, inset dark display, understated metallic edge. |
| ui3.jpg | Graphite body, white readouts and restrained hardware proportions; no colored accent. |
| ui2.jpg | Layered dark surfaces, muted inactive states, thin rules. |
| ui.jpg | Monospaced numbers, calibration ticks and generous negative space, all monochrome. |
| Image_20260928150913_14_3.jpg | Black field, restrained point texture, architectural order. |
| Image_20260928150912_13_3.jpg | Clearly separated information hierarchy and quiet contextual controls. |
| Image_20260928150910_12_3.jpg | Engineering labels, quiet technical typography. |
| Image_20260928150909_11_3.jpg | Hairline instrumentation and calibrated scales; no decorative overload. |
| Image_20260928150907_10_3.jpg | Simple geometric controls, active inversion, exact alignment. |
| Image_20260928150905_9_3.jpg | Machined housing, inset controls, precision borders. |

Current direction (2026-10-01, implementation pending): an independent, clean monochrome HUD with meaningful real instrumentation. Serpantinum is no longer a design or runtime reference. Remove its dependencies without hiding functionality or changing live shortcuts. Controlled visual hover expansion is allowed; rail hover text/tooltips must be removed. Clicks reveal panels from their controls without delaying input.

The supplied mainDesigns calendar replaces the radial-only direction: weather left, liquid hardware meters centrally, calendar right. The frame reveals downward, followed by subframes in a newly randomized order over approximately 1.5 seconds. Keep input immediate, honor reduced motion, avoid rapid high-contrast flashes, and never fabricate weather or telemetry. The shipped staged calendar still uses radial ticks until this replacement is verified.

Terminal work may inspect TemperedOS only as the explicitly authorized terminal visual reference, with more spacing and monochrome treatment. No unrelated legacy code or systems may be imported. The compact power HUD must open first and require deliberate confirmation for disruptive actions; tests must disable those actions.

Icon system 01: 60 separate transparent 24px SVGs with 1.5px rounded outline strokes, explicit pure black/white variants, and a font-derived Turret Road G. Existing Canvas controls are not yet migrated. See icons.md.

The top bar is the scope of version 0.1. Other desktop surfaces will follow the user's designs. Existing keybindings are never edited.
