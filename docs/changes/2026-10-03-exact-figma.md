# 2026-10-03 / Desktop 1 and Settings reference pass

Source: [current Figma](https://www.figma.com/design/mImDMio3PmIliY2Xyk3ODO/hyprland-rice-design), Desktop 1 and Desktop 2. Read the visible nested properties rather than treating browser zoom as design pixels. [Measured specification](../figma-spec.md).

## Changes

- Bundled plain JetBrains Mono Light/Regular/Medium/Bold under OFL. The previous plain-family lookup fell back to Noto Sans Mono. Workspace, calendar weather and Settings profile labels now use the measured family; sidebar/navigation retain the measured Nerd Font family.
- Settings uses both original Figma portrait fills with continuous G2 image crops, measured 16/20 Bold profile names and 10 Regular subtitle. General is sparse again. Search fill is #D9D9D9 at 17%, with the measured 16px glyph. Navigation stays in its 231 × 215.2 housing; fourteen categories remain accessible by scroll/search. Row separators, selection, spacing and toggles follow the measured positions.
- Desktop 1 rail fill is #191919 with the two measured dividers. Sidebar statuses use the measured positions and 12 Bold battery label, anchored to the right. Its updated three-button header includes power, gear and notifications. Power opens the HUD only; no session action was tested.
- Calendar returns to the latest Figma's 733 × 310 composition, superseding the older 10% widening instruction. Weather uses the measured plain-family type; existing real telemetry, weather-specific motion and reduced motion remain intact.
- Reaffirmed main rail/calendar/sidebar radius7 through the shared Theme token. Expanded outside-stroke outlines use radius + stroke width, not a different main-frame radius. Nested WLAN/Bluetooth wells retain 15 − 4 = 11. Settings frame10 and portrait21 follow their separately measured Figma values. Continuous G2 corners are retained throughout.
- Isolated Settings preview now starts at (524,212), matching the artboard. Reference captures use #151515 and explicit sample data. Production time, weather, volume, workspaces and wallpaper are not replaced with fixtures.
- Fixed calendar-to-Settings navigation reading a destroyed QML item's status. Verification selects the correct page before calendar checks and waits for a newly written screenshot rather than accepting an older capture.

Affected paths: `config/quickshell/ghost-bar/{Theme,Workspaces,Rail,CalendarPanel,CalendarWindow,SidebarFigmaBody,SettingsPanel,PanelContent,preview,G2Image}.qml`, `qmldir`, `fonts/`, `artwork/profile.jpg`, `scripts/verify_{settings,calendar}.py`, documentation and preview captures.

## Verification and scope

36 Python tests and 15 launcher assertions pass. The isolated Settings check covers all fourteen pages, (524,212), 1024 × 699, scale1, 215.2 navigation height, loaded plain font family, empty search, sidebar grouping/long names, output captures and calendar-to-Settings navigation. Calendar checks cover 733/310 ratio, randomized 1.5-second reveal, rain motion, storm pulse, reduced motion and closed-state suspension. Default staging install succeeds. Only expected offscreen-backend warnings occur: no Hyprland connection and unsupported native masks. No QML exception remains after the navigation fix.

This pass is staged only under the current AGENTS.md. No installed profile, autostart, active process, wallpaper or shortcut was edited. Native compositor placement, input and GPU-rendered parity of these new changes are not verified. No reboot, logout, lock, suspend, power, audio/network/brightness setter or hardware action ran.

## Output

Actual isolated QML, explicitly sample data: [Desktop 1](../../site/assets/desktop-frame.webp), [calendar](../../site/assets/calendar-frame.webp), [sidebar](../../site/assets/sidebar-frame.webp), [rail](../../site/assets/rail-frame.webp), [Settings](../../site/assets/settings-general.webp), [Sound](../../site/assets/settings-sound.webp), [Battery](../../site/assets/settings-battery.webp). [Pages preview](https://dsksnkz.github.io/ghOSt/).

The site's default wallpaper remains a separate 1920 × 1080 export of the active HDMI wallpaper, `flow 7.jpg`, inspected through the current wallpaper cache and source image. The original is unchanged. Reference component captures use the Figma background instead, allowing geometry/material comparison without altering the user's desktop. All fourteen Settings category captures are refreshed in the gallery.

## Remaining parity gaps

Not a claim of 100% pixel identity. The functional date grid's type is inferred from Figma's raster; the sidebar pattern/outer scrollbar, exact image transforms, native Settings placement and unmeasured pencil control need further work. Decorative author text is excluded under the functional-text-only project rule. Continuous G2 corners implement the user's explicit correction, without claiming an exported Figma smoothing path. Embedded EQ, independent notifications/lock and broader migration remain pending; features were not silently removed.

GitHub prompt blob: `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`; design screenshot blob: `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`; `mainDesigns/1`: `8b137891791fe96927ad78e64b0aad7bded08bdc`. Local copies matched remote listing again before handoff. The prompt revision stays pending.

Snapshot: `.local/backups/2026-10-03-exact-figma/`, exact affected project profile/docs/site paths. Restore only those affected project paths for rollback; newly added font/artwork/G2Image files can be left unused. Originals and unrelated untracked work were preserved. Private evidence: `.local/verification/exact-figma/output/`.
