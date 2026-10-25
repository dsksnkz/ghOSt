# Icons

ghOSt uses Google Material Symbols Outlined for its 63 system/control icon IDs,
plus the ghOSt ghost brand mark. Both folder IDs share one Material
folder. Six weather variants use Google's lighter weight 200; other controls use
regular 400, unfilled. Third-party application logos retain their own identities.

The rail, sidebar, Settings, calendar, built-in launcher, OSD and wallpaper chooser
use the shared SVG component. Sizes, positions, actions and animation timing are
unchanged. The existing Files folder overlay also uses Material folders; other
system-theme icons inherit their previous theme. The separate, independently
configured `ghost-launcher` is outside this repository and is not overwritten.

## Source and licence

Official source: [Google Material icons](https://github.com/google/material-design-icons).
Controls are pinned to commit `10ecc14790612ca8fd164e3f4ffe9c16fc50d5b7`.
Light weather symbols come from Google's SVG endpoint. Downloaded SVGs and their
source URLs/SHA-256 hashes are committed in `assets/material-symbols/`.
Normal builds are offline. No package installation, icon font or network runtime.

Material Symbols are Apache 2.0; full licence and modification notice ship in both
export directories. Google artwork is normalized to a 24 × 24 viewBox with a
one-pixel raster safety margin, exported in black/white without editing its paths.
The ghost brand mark (2026-10-25, replacing the Turret Road G) is original ghOSt
artwork drawn from the user's sketch: one solid 24 × 24 shape with pixel-aligned
eye and mouth cutouts, source `assets/material-symbols/ghost-brand.svg`.

## Files and rebuild

- `assets/material-symbols/`: upstream SVGs, catalogue, hashes and licence.
- `scripts/build_icons.py`: stable semantic mapping and deterministic exports.
- `config/quickshell/ghost-bar/icons/`: runtime files.
- `site/assets/icons/`: byte-identical Pages exports.
- [Full sheet](../assets/icons-rounded-sheet.svg) · [Folder](../assets/folder-rounded-preview.svg).

```sh
python3 scripts/build_icons.py
python3 scripts/build_icons.py --check
python3 -m unittest discover -s tests
```

Only an intentional upstream refresh uses `--fetch`; review changes and hashes.
Tests render every control in both tones at 24/48 pixels, checking nonempty
artwork, transparent margins, tone parity, offline generation and source hashes.

Usage remains `SvgIcon { name: "settings"; black: false; width: 24; height: 24 }`.
Every SVG stands alone. HTML images need the explicit black or white export;
inline SVG inherits `currentColor`. Preserve accessible button names.

Native icons cache at 2× device resolution, minimum48px, with mipmaps for the
existing fractional parent scales. This improves sampling without enlarging the
logical icons, altering layout or changing animation timing.
