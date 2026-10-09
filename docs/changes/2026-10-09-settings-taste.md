# Settings and its sidebar

Native Settings now has clearer headings, grouped controls and live summaries.
The left navigation has larger search, steadier alignment and more row spacing.

## Design audit and Taste Skill

Reading this as: a native Settings redesign for the existing laptop user, with
ghOSt's monochrome, monospaced language and restrained state-change motion.
Redesign-preserve; DESIGN_VARIANCE 3, MOTION_INTENSITY 4, VISUAL_DENSITY 4.

Before: General's lower area was unused; other pages used small, loose controls,
dimmed read-only information and an inactive slider as a storage measurement.
Search was small and low-contrast; navigation icons/text jumped sideways on
selection. Fourteen categories, original portraits, keyboard interaction,
search, grouped navigation and the moving selector already worked.

The complete installed Taste Skill was read. It explicitly excludes dense
product UI, so its audit, preservation, hierarchy, spacing, contrast and
motivated-motion guidance was adapted at the user's explicit request. Web-only
React/Tailwind/library-icon, hero, SEO, photography, Lighthouse and dual-theme
prescriptions do not apply to this native QML surface. No dependency was added.
The user's owned icons, supplied composition and dark material take precedence.

Current GitHub main was read: prompts.md blob
`f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`, mainDesigns screenshot
`9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`, placeholder
`8b137891791fe96927ad78e64b0aad7bded08bdc`; local copies match.
Editable Figma right pane `36:270` still measures 762x699, radius10, #252525,
x786/y212. Retained the 1024x699 composition and 262px left pane. This is a
deliberate requested refinement, not a new pixel-parity claim.

## Implementation

- SettingsPanel.qml owns a small local color/height token set and shared padded
  groups, summary cards, action rows and toggles. Native backend bindings remain.
- General retains the original 116px portrait/radius21, name pencil and Info
  entry. Battery/free storage summaries navigate to their real pages. Sound and
  accessibility rows use current state. Creator text explicitly names ChatGPT
  and dsksnkz in General and System information.
- Right-page headings have a matching owned glyph; labels use 12-13px hierarchy,
  controls use 56px rows, cards radius10 and icon wells radius8, all continuous.
  Sound has separate output/input groups; Brightness, widgets and system facts
  have appropriate independent groups. Read-only information stays legible.
  Device values reserve only the width they need, giving long names more room.
- Battery distinguishes disabled recording from measured display-on time and
  retains real history/empty states. Storage uses real used/free figures and a
  passive accessible meter rather than a disabled slider.
- Sidebar preserves the fixed original 48px portrait/radius11 and gear. Search
  is 227x32/radius8 with a glyph, visible focus border and functional clear key.
  Its placeholder contrast improves. Navigation starts y145, ends y675, with
  44px rows, 8px row gaps and 16px group gaps; 744px content scrolls in 530px.
  Icons and text no longer shift on selection. No dividers or selected hover
  change. The 280ms moving highlight, instant reduced motion, labels and all
  fourteen categories remain. No category or existing setter was removed.
- SettingsWindow's existing capture IPC now exports safe native pages. It
  refuses network/Bluetooth/notification/wallpaper pages; Battery exports only
  the charge card, never private history or display-on time. It cancels when the
  user closes the window or changes page before capture completes.

## Verification

- 64 Python tests pass, including isolated installation and mocked backend
  actions. Icon generator freshness and production surface compilation pass.
- Actual offscreen Qt events cover search typing/clear, fixed header actions,
  selected/unselected hover, nav scrolling/Bézier travel, overview navigation,
  passive storage ratio, all-page control bounds, right-page wheel scrolling,
  page-scroll reset, reduced-motion selection and charge-only capture target.
- Existing 10 router transitions, 14-page polling/real 5s timer/fixture safety,
  and 12 scan-demand transitions pass. Launcher, workspace, corner geometry,
  24,300 wave vertices, 128 network cases and five website tests pass. The website
  tests do not rebuild or activate a preview.
- Relevant text contrasts measured: primary/card 11.85:1, secondary/card 6.75:1,
  search placeholder 5.65:1, nav text 9.15:1, selected nav text 8.49:1.
- Native output inspected below. Settled selection checks report zero position
  error. Native page requests and backend reads were exercised without changing
  volume, brightness, networks, hostname, image or history preferences in tests.
- Hot-reloaded only the two affected installed ghOSt files; both match source.
  ghOSt PID222465 and legacy PID1824 remain. Hyprland config errors are empty.
  No shortcuts, wallpaper, autostart, legacy services or system themes changed.

Native captures, not fixtures or another preview:

- [General and sidebar](../images/2026-10-09-settings-taste/general-native.png)
- [Sound](../images/2026-10-09-settings-taste/sound-native.png)
- [Storage](../images/2026-10-09-settings-taste/storage-native.png)
- [Widget controls](../images/2026-10-09-settings-taste/widgets-native.png)
- [System information](../images/2026-10-09-settings-taste/about-native.png)
- [Battery charge only](../images/2026-10-09-settings-taste/battery-charge-native.png)

Private lists, usage history/time, failed/interrupted captures and foreign app
content are excluded from publication. Original images remain unchanged.

## Recovery and remaining limits

Exact pre-edit project/live copies:
`.local/backups/2026-10-09-settings-taste-qrjsqM/`.
Source/docs/test originals and later-scoped verifier originals are retained.
Three unrelated untracked files remain untouched. No runtime was restarted.

No claim of 100% Figma parity or completion of the broader prompts.md backlog.
Real system setters, dialogs and physical touch were not activated by this pass.
Navigation/geometry tests use fixtures; published captures are actual native
output. No gameplay, drivers or hardware settings were changed.

Publication checkpoint: implementation, tests and native captures complete;
authorized publication and fresh committed-archive check still pending.
