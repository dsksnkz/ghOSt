# 2026-10-03 / continuation checkpoint

2026-10-04 scheduled continuation: Settings grouping, both portrait entry points/private copies, PC-name editor and creator Info are staged and isolated-tested alongside earlier corrections. [Current record](changes/2026-10-04-settings.md) supersedes historical pending states below. Next: independent notifications, 3D workspace motion and left rail alignment/dividers; then remaining measured-layer/native parity and backends. Preserve activation boundaries; full prompt remains pending.

2026-10-04 manual continuation: [small corrections](changes/2026-10-04-small-corrections.md) implemented and isolated-tested sidebar entrance direction/radii/status sizes, calendar action radii and rail font/triangle alignment. These are no longer unimplemented. Settings grouping/portrait/name/credits, independent notifications, 3D wheel and left rail dividers remain pending. Source/output remains unpublished and inactive; preserve the dirty tree.

Latest corrections and next03:20 London start: [next-scheduled-corrections.md](next-scheduled-corrections.md). This overrides historical notes below, especially plain rail fonts, one Settings housing, right-to-left item entrances and omitted author attribution. New corrections are not implemented. Existing source/output remains unfinished and unpublished.

Newest: [Desktop 1 and Settings reference pass](changes/2026-10-03-exact-figma.md) is staged and isolated-tested. Both Figma desktops are in scope. Plain fonts, original portraits, compact navigation, exact preview placement, sidebar status/header geometry, rail fill/dividers and 733 × 310 calendar replace the older approximations. Do not reapply the superseded 10% widening. Active installed files remain from the previous deployment. Next: exact raster/date-grid and pattern/scrollbar parity, pencil function/image transforms, native placement/input/GPU-render verification, then remaining independent backends. Current AGENTS.md requires isolated work, no automatic activation.

Latest: manual work resumed and the user explicitly authorized the rail-autostart replacement. Settings is now built; native rail reservation and old rail removal are verified. [Current change record](changes/2026-10-03-settings-polish.md) supersedes the old partial-state entries below. Continue with exact Figma asset/layer matching, embedded equalizer controls, independent notifications/lock, external brightness and native input/multi-monitor verification. Preserve all snapshots and live shortcut combinations. Scheduled work still must not broaden activation beyond explicit user requests.

## Earlier pause checkpoint

The user requested stopping the manual pass and resuming the existing weekday five-hour schedule. This is unfinished work, not a completed release. Preserve current dirty files and snapshots; no new commit or publication was completed in this pass.

## Resume priorities

1. Fix the rail work area/black band before polishing further. `RailReservation.qml` is staged and copied into the installed ghOSt profile, but its layer did not map during the last check: Hyprland still reserved 40 px, not the intended 64 px at 1920 width. Do not claim this fixed. Do not stop the legacy shell or double-count its reservation. Inspect the running ghOSt instance and test the isolated/native ghOSt change safely.
2. Finish validation of the partial G2 material, calendar widening, sidebar group animation/fades, stationary workspace triangle, hover-color-only controls and restrained power glow. Most polish is source-only, not installed into the user's running rail/calendar/sidebar. Use isolated fixtures first.
3. Build the new Figma Settings app and connect real backends. No full Settings app was implemented yet; current Settings is the older small overlay. Cover sound volume and input/output, existing EasyEffects equalizer access, battery/history/screen time, sidebar widgets, brightness, wallpaper and notifications. Never invent history or show disconnected controls as working.
4. Capture clean actual output, rerun tests, document results, then publish verified work under the user's existing GitHub/Pages authorization. Private screenshots with chats/real nearby SSIDs must not be published.

## Partial changes already made

- New `G2Surface.qml` uses continuous cubic vector corners; rounded surfaces use this component. Last offscreen QML load succeeded after correcting border and gradient binding errors. Complete visual/performance tests remain pending.
- New `FadeLabel.qml` fades long WLAN/Bluetooth names at the right edge instead of ellipsis. Test long names explicitly.
- `SidebarFigmaBody.qml` has larger right-anchored status icons, a gear, and six randomized entrance groups with WLAN/Bluetooth kept whole. Outer left-to-right entrance is retained. Verify final alignment and interaction.
- Calendar design width is 806.3 instead of 733, retaining 310 height and existing type sizes. Central instruments shift 36.65 px, right grid 73.3 px, bottom controls 36.65 px. Verify sizing on different monitors.
- Workspace triangle is outside the moving number track. `workspace_scroll.py` includes 1–5 and only populated higher workspaces, handles accumulated notches and serializes rapid requests. The helper was installed into the ghOSt profile; only live Super+mouse_up/down and scroll delay were changed under the user's explicit request. Hyprland reload succeeded with empty config errors; dry-run returned expected target. No real workspace transition was automated. Other shortcuts remain intact.
- Rail power glow, press-only scaling and hover color feedback are staged. Full regression tests still required.

Snapshot: `.local/backups/2026-10-03-polish/` contains affected source/profile/config originals. Earlier Figma pass snapshot remains `.local/backups/2026-10-03-figma-pass/`. Evidence includes `.local/verification/polish-g2-composition.png` (needs visual review). Do not treat the previous Figma screenshots as verified screenshots of this newer polish.

## Latest reference and measured Settings nodes

Authoritative Figma: https://www.figma.com/design/mImDMio3PmIliY2Xyk3ODO/hyprland-rice-design . Signed-in browser tab was accessible; read editable properties rather than guessing from a screenshot. Existing `docs/figma-spec.md` covers the earlier rail/sidebar/calendar, superseded by newer user corrections.

| Node | Measured properties |
| --- | --- |
| Desktop 2 `36:82` | 1920 × 1080, fill `#151515` |
| Main settings frame `36:269` | x524 y212, 1024 × 699, radius10, `#2C2C2C` |
| Right pane `36:270` | x786 y212, 762 × 699, radius10, `#252525`; left pane262 wide |
| Settings glyph `36:271` | x541 y236, 32 × 32, white |
| Search group `36:280` | x586 y241, 186 × 24.17 |
| Right portrait `36:371` | x1109 y265, 116 × 116, radius21, raster asset |
| Wireless nav group `36:314` | x551 y397, 205.93 × 35, `#2F2F2F`/white |
| Wireless label `36:310` | x591 y402, 165.93 × 18; JetBrainsMono Nerd Font Mono Regular11, white, auto line-height, letter-spacing0 |
| Following nav group `36:315` | x551 y439, 205.93 × 35 |

Other visible settings nodes: `36:311` profile group, `36:323`, `36:331`, `36:339`, `36:357`, `36:358`, `36:359`, `36:361`, `36:369`, `37:28`. Continue measuring their layout/functions before implementation. Only functional labels, values, errors and actionable instructions belong on the desktop, not the Figma's decorative author copy.

Existing standard utilities include EasyEffects, PipeWire/Pulse tools, brightnessctl, awww and swaync-client. PipeWire QML node tracking is needed for live device/audio properties; preferred default sink/source is writable. Do not steal an occupied notification/authentication service or introduce legacy helpers. Independent notifications and lock remain pending architecture gaps.

Latest user design requirements: all rounded corners G2; main rail/sidebar/calendar outer radius7; deliberate nested radius/padding; 10% wider full calendar; right-anchored larger sidebar status; long-name fades; randomized grouped sidebar entrances; gear icon; no hover scale; stationary workspace triangle; desktop wheel eligibility as above; sharp premium monochrome slate material. Samsung/NothingOS/old rice are allowed visual references only, never runtime dependencies. User-facing updates should only name the working part.

GitHub source blobs last matched: prompts.md `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`; mainDesigns screenshot `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`. Recheck latest remote versions each scheduled pass. The prompt revision is not completed.
