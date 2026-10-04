# Design

Launcher: a 392 px panel sharing the rail's material and click-origin transition. A 44 px search field, six 46 px result rows, 16 px section rhythm, and a 90ms selection slide. The G control opens it; no hover expansion or shortcut replacement. Native catalogue entries use ghOSt's own monochrome category symbols, with explicit names for recognition. Pins persist locally. Search and empty states preserve the panel geometry.

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

Current direction (2026-10-03): implement the supplied Figma, a clean monochrome HUD with real instrumentation. New controls use hover color only, never hover scaling; press feedback is allowed. Rail tooltips are disabled while accessible names remain. Main rail/calendar/sidebar radii are 7 px, continuous cubic G2 corners; inset radius is max(0, outer radius minus padding). Older-rice appearances may be inspected only as visual references under the user's latest exception; they must not supply runtime code, helpers or imports.

The supplied mainDesigns calendar replaces the radial-only direction: weather left, liquid hardware meters centrally, calendar right. Its current design plane is733 × 310; the later exact-proportions correction superseded the temporary10% widening. The frame reveals downward, followed by subframes in a newly randomized order over1.5 seconds. London is the user-approved weather location. Rain moves and storm lightning pulses occasionally; reduced motion stops both. Never fabricate weather or telemetry.

Settings uses the measured1024 × 699 frame:262 px navigation and762 px content. Colors, original portrait artwork, first navigation positions,11 px navigation type and54 × 20 toggle geometry follow inspected nodes. The original five functions keep their215.2 px housing; added categories have separate frames. Portraits use21 px G2 corners, frames10 px and icon wells8 px. Both portraits share a local picture chooser; the pencil opens an explicit PC-name edit flow. User-requested creator Info follows the measured11 px Regular label. Undrawn pages reuse those materials. Full pixel parity is not claimed.

Terminal work may inspect TemperedOS only as the explicitly authorized terminal visual reference, with more spacing and monochrome treatment. No unrelated legacy code or systems may be imported. The compact power HUD must open first and require deliberate confirmation for disruptive actions; tests must disable those actions.

Icon system 01:61 separate transparent24 px SVGs with1.5 px rounded outline strokes, explicit pure black/white variants, and a font-derived Turret Road G. Existing Canvas controls are not yet migrated. See icons.md.

Existing shortcut combinations are preserved. Staged migration mappings are not activated automatically. The October 3 manual rail-autostart replacement was explicitly authorized and keeps unrelated services intact.
