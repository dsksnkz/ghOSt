# Rounded icons and Settings

The [direct request and later corrections](../requests/2026-10-09-icons-settings.md)
supersede older navigation materials/sizing. This is a desktop-visible pass,
not a new preview or system theme.

## Implementation

All 64 owned glyphs share 24px vectors, 2px outlines, rounded joins and rounded
inner/outer corners. The canonical generator fillets straight joins while keeping
curves intact and limiting fillets on short edges. Both folder names use the
corrected rounded cavities. Every black/white shell export matches its site copy.
The former Canvas compatibility icon renderer now uses these same SVGs, including
Launcher, older panels and gauges. Brand, workspace triangle and animated weather
also share the family; fixed triangle coordinates and rain/lightning animation
remain. No third-party icon library, package, application theme or Nautilus change.

Settings retains 1024×699, a 262px navigation pane and its original right-page
content/functions. The screenshot is primary. Current editable Figma evidence:
right pane `36:270` remains x786/y212, 762×699, radius10, #252525; left portrait
`36:282` is x541/y230, 48×48, radius11; host `36:284` is x606/y234, JetBrains Mono
Bold16; search `114:18` is x541/y296, 227×24.17, radius4. Coordinates are relative
to main origin524/212. The large General portrait remains116px/radius21.
The blue screenshot outline is an editor selection, not a product border.

The fixed left header uses the original portrait, host, Your PC, a General gear
and the full-width search field. Navigation starts at137px (after the requested
extra16px top gap), rows remain42px with6px between selections and16px between
logical groups. Visible list height538, content696; all14 pages remain reachable.
No grey group housings or separator lines. The new screenshot's glyph proportions
supersede the old40% instruction: 28px wells/60% glyphs. The rounded selector keeps
its280ms Bézier motion. Selected rows have no hover color overlay; other rows keep
it, and deliberate press feedback remains. Reduced motion is immediate.

## Verification and output

64 Python tests and all SVG tone/transparency/bounds/parity checks pass. Actual Qt
input tests cover selected vs unselected hover, fixed header during scrolling,
search typing, portrait/gear actions, all14 pages and intermediate/settled selector
positions. Production surfaces compile without creating windows or invoking
setters. Router, polling and network-binding tests and existing JS suites pass.

- [Native Settings content](../images/2026-10-09-icons-settings/settings-native.png)
- [Native Calendar](../images/2026-10-09-icons-settings/calendar-native.png)
- [Native rail navigation](../images/2026-10-09-icons-settings/rail-navigation-native.png)
- [Native rail clock](../images/2026-10-09-icons-settings/rail-clock-native.png)
- [Native rail status](../images/2026-10-09-icons-settings/rail-status-native.png)
- [Native Sidebar header](../images/2026-10-09-icons-settings/sidebar-header-native.png)
- [Every vector](../../assets/icons-rounded-sheet.svg)

Settings capture uses the actual visible native General component, not fixtures
or another window; its IPC capture refuses private list/history pages and cancels
if the page changes. Other public images are compositor crops. Interrupted frames
containing chats/network names remain ignored, never published. A later safe
Sidebar header capture succeeded; full private WLAN lists are excluded. Native
all-page hardware actions and exact full-Figma pixel parity are not claimed.

Installed affected runtime files match source. ghOSt PID222465 and legacy PID1824
survived hot reload. Hyprland config errors remain empty; no shortcut, wallpaper,
autostart, radio/media setter or notification-owner change. Original prompt/design
Git blobs match current GitHub main (`f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`,
`9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`, `8b137891791fe96927ad78e64b0aad7bded08bdc`).

## Recovery and release

Exact project/live originals are in
`.local/backups/2026-10-09-icons-settings-vOt2Co/`; additional checkpoints retain
the versions before line removal, top gap and row gap. Restore only affected
paths after reconciling later edits. No unrelated dirty files are included.
Publication pending. Broader prompts.md remains unfinished.
