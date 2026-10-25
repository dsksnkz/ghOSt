# Ghost brand mark — 25 October 2026

User: "Use the clean ghost as ghOSt's brand icon and deploy it." The design was
developed this session from the user's own drawings (several rounds; the final
brief was "use it as reference but not 100%. make it look more pixel perfect and
professional").

## Change

- `assets/material-symbols/ghost-brand.svg` now holds the ghost: one solid
  24 × 24 shape (egg head, raised arms, slight lean right) with even-odd
  cutouts for the eyes (2 × 3 px, pixel-aligned) and a small V mouth.
  It replaces the Turret Road G.
- `scripts/build_icons.py` regenerated `ghost.svg` (white/black) for the shell
  and site, the icon sheet and both NOTICE files. The NOTICE wording now names
  the ghost as original ghOSt artwork. All 63 Material icons are unchanged.
- `SvgIcon.qml` cache key bumped to `ghost-20261025` so a running shell loads
  the new file.
- `docs/images/2026-10-25-ghost-brand/ghost-illustration.svg`: outlined
  illustration variant (light body, fine outline, eye highlights) for larger
  surfaces. It is not wired into any surface yet.

## Verification and deployment

- `build_icons.py --check`, `tests.test_icons` (raster checks), site test and
  surface compile pass. An offscreen Qt render showed the cutouts at 96/44/22 px,
  in white and black.
- Deployed `icons/{white,black}/ghost.svg`, `icons/NOTICE.txt`, `SvgIcon.qml` and
  the Intro app icon (`~/.local/share/icons/hicolor/scalable/apps/ghost-intro.svg`).
  Memory and CS2 were checked first. One reload, `Configuration Loaded`.
- Not checked on the live desktop: surfaces were not opened to view the new mark.

Rollback: `.local/backups/2026-10-25-ghost-brand/` (source, generated, live and
Intro icon copies). Design files: `.local/design/2026-10-25-ghost-icon/`.
