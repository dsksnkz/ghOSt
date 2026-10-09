# Icons

64 separate icons, each available as a transparent black or white SVG. Common settings, input, connectivity, hardware, session, weather and actions share a 24 × 24 viewBox and 2px rounded stroke. Straight joins are filleted and rectangular outlines have rounded inner corners as well as outer corners. The Turret Road G remains a filled, now softly rounded font outline, not the retired ghost mascot.

`folder-rounded` uses curved outer corners and explicitly rounded inner cutouts
in both the tab and the front compartment. It is one design in two inverse monochrome exports; the original
`folder` now uses that same corrected geometry. [Folder](../assets/folder-rounded-preview.svg) · [Full set](../assets/icons-rounded-sheet.svg).

The shaded layered experiment was removed at the user's request. No Nautilus
theme is applied.

`Icon.qml`, `SvgIcon.qml`, the brand, weather glyph and stationary workspace
indicator all share the generated assets. The added `lightning` keeps its
independent opacity animation; `workspace-indicator` keeps the fixed triangle
position. Third-party application/system themes are not changed.

[Browse and download](https://dsksnkz.github.io/ghOSt/icons.html).

## Files

- `config/quickshell/ghost-bar/icons/black/<name>.svg`
- `config/quickshell/ghost-bar/icons/white/<name>.svg`
- `site/assets/icons/`: identical files for GitHub Pages.
- `manifest.json`: stable names and categories.

Each file stands alone: no sprite, external font, image, script, icon theme or rice dependency. Preview tile backgrounds are not included in the SVG. The `ghost.svg` mark uses the bundled Turret Road Bold G outline; its existing [OFL](../config/quickshell/ghost-bar/fonts/OFL-TurretRoad.txt) applies. All other geometry is authored for ghOSt.

## Use

For HTML images, choose the desired file directly. CSS `color` on an `<img>` cannot recolor its SVG contents:

```html
<img src="assets/icons/white/settings.svg" width="24" height="24" alt="Settings">
```

For inline SVG, set `style="color:#000"` or `style="color:#fff"` on the `<svg>` element. Paths inherit `currentColor`. Give icon-only buttons accessible names; mark decorative icons hidden from accessibility.

In Quickshell, the new component selects an explicit variant without a shader:

```qml
SvgIcon { name: "settings"; black: false; width: 24; height: 24 }
```

Prefer 18, 24 or 32 logical pixels and verify small-size legibility. Keep text labels for unfamiliar actions. Existing Canvas-based controls are not migrated by this asset-only revision; the new component is tested in the isolated icon preview.

## Rebuild and verify

Author geometry in `scripts/build_icons.py`, then regenerate both destinations. Dependencies for development only: Python, fontTools, Pillow and librsvg (`rsvg-convert`). No extra dependency is needed to use the committed SVGs.

```sh
python3 scripts/build_icons.py
python3 scripts/build_icons.py --check
python3 -m unittest discover -s tests
```

Checks cover name coverage, XML structure, web/shell byte parity, empty or clipped artwork, actual transparent pixel margins, and identical alpha geometry in pure-black/pure-white renders at 24px and 48px.
