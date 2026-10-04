# Figma measurements / 2026-10-03

## 2026-10-04 actual corner paths

Editable nodes rechecked: Bluetooth30:62=144×222/r15/smoothing0%; inner30:63=134×213/r11/smoothing0%; portrait36:371=116×116/r21/smoothing60%; main Settings36:269=1024×699/r10/smoothing60%. Navigation selection36:369 is square. Shared geometry now uses actual arc/transition paths, not the nearly-square single cubic. Settings grey/icon materials follow explicit G2 at10/8px; added layers are not all measured Figma counterparts. [Verification](changes/2026-10-04-corners.md).

## 2026-10-04 corrections and measurements

Latest direct corrections supersede historical values below: all rail fonts Nerd Mono; sidebar controls15 px with11 px WLAN/Bluetooth wells and enlarged136×26 right-anchored status group; calendar bottom controls request15 px (24 px controls clamp to12 px effective); Settings portraits21 px, frames10 px and icon wells8 px, all continuous corners. Retain main7 px frames and733×310 calendar.

Read editable Figma nodes this pass: pencil `37:28` at artboard(1219,404),11×11; General Info group `36:379` at(1067,437),199×18 with9 px gap; attribution `36:378` at(1094,438),172×15, JetBrains Mono Regular11, auto line-height,0% letter spacing and white fill. Exact text: `ghOSt - by you and Dsksnkz`. This explicit user request overrides older credit omission. The26 px pencil hit target centers the measured11 px glyph. Added groupings/name dialog are functional extensions using those materials, not measured Figma layers.

First five navigation categories retain215.2 px housing. Added three-category frames are131.2 px (`3 × 42 + 5.2`),12 px gaps,500 px scrolling viewport. Search filters without merging the groups. [Output and verification](changes/2026-10-04-settings.md).

Source: the signed-in [current user design](https://www.figma.com/design/mImDMio3PmIliY2Xyk3ODO/hyprland-rice-design). Both Desktop 1 and Desktop 2 were inspected through visible Design properties, including nested layers, image metadata and gradient stops. Coordinates below use the 1920 × 1080 artboard, not the browser's zoomed screenshot. No design content was changed.

## Coordinate system

`scale = outputLogicalWidth / 1920`. Coordinate, spacing, font size and radius use that same scale. The current HDMI monitor was verified at 1920 × 1080, scale 1. No monitor setting was changed. The isolated reference preview uses the same 1920 × 1080 plane and #151515 background; the user's live wallpaper is preserved.

| Surface | Artboard rectangle | Fill | Radius / stroke |
| --- | --- | --- | --- |
| Rail `1:4` | 19,16 / 1882 × 46 | #191919 | 7 / outside 1 #4D4D4D |
| Calendar `2:35`, background `2:33` | 594,82 / 733 × 310 | #161616 → #1C1C1C | 7 / inside 1 #474747 |
| Sidebar background `27:29` | -37,146 / 391 × 790 | 12% #181818 → 100% #1B1B1B | 7 / outside 2 #5D5D5D |
| WLAN `31:21` | 28,266 / 144 × 222 | #262626 | 15 / inside 1 #323232 |
| Bluetooth `31:22` | 189,266 / 144 × 222 | same | same |
| Card list well `30:42` | 33,270 / 134 × 213 | #393939 | 11 |
| Card cap `30:43` | 33,270 / 134 × 36 | #CECECE | 11 |
| Volume / brightness `32:66`, `32:65` | 29,507 and 29,561 / 304 × 34 | #262626 / #CECECE fill | pill / 1 #323232 |
| Notifications `32:64`, `32:31` | 29,616 / 304 × 284 | #262626 | 15 / inside 1 #323232 |

Nested card radius is `max(0, 15 − 4) = 11`, not another arbitrary radius. An outside stroke is a separate expanded outline: outer radius = fill radius + stroke width. Slider fill clips to the pill but its partial endpoint is straight. Liquid fill inverts the diamond's cross-sectional area; the actual percentage determines filled area rather than a decorative fixed level.

## Type

| Text / node | Family | Size / weight | Color |
| --- | --- | --- | --- |
| Rail time `2:2` | Turret Road | 26 Bold | #FFFFFF |
| Rail date / weather `2:5`, `2:4` | Turret Road | 15 Regular | #FFFFFF |
| Active workspace `1:5` | JetBrains Mono | 15 Bold | #FFFFFF |
| Neighbor workspace `1:9`, `1:8` | JetBrains Mono | 11 Medium | #B8B8B8 |
| Weather title / temperature `6:14`, `6:16` | JetBrains Mono | 20 Light | #FFFFFF |
| Active forecast `6:20` | JetBrains Mono | 13 Light | #FFFFFF |
| Instrument labels `2:41`, `2:42`, `2:44` | Turret Road | 15 Bold | #FFFFFF |
| Instrument values `4:7`, `4:8`, `4:9` | Turret Road | 15 Medium | #181818 |
| Sidebar time `28:11` | JetBrainsMono Nerd Font Mono | 48 Regular | #FFFFFF |
| WLAN heading `30:41` | JetBrainsMono Nerd Font Mono | 14 Bold | #000000 |
| Device row `30:44` | JetBrainsMono Nerd Font Mono | 11 Regular | #FFFFFF |
| Notification title `32:38` | JetBrainsMono Nerd Font Mono | 11 Bold | #FFFFFF |
| Notification detail / empty state `32:42`, `32:45` | JetBrainsMono Nerd Font Mono | 11 Light | #FFFFFF |

Turret Road Regular/Medium/Bold and plain JetBrains Mono Light/Regular/Medium/Bold are bundled with their OFL licenses. Plain JetBrains Mono previously resolved to Noto Sans Mono on this laptop; profile-local FontLoaders now provide the measured family without a system installation. Nerd Font Mono remains the explicit family for the sidebar and Settings navigation.

## Calendar and controls

GPU/RAM squares are 87 × 87, 45° rotation, radius 15, #313131; their rotated bounding boxes are 123 × 123. Background origins within the frame are GPU (235,27), RAM (375.01,27), CPU (305,97.01). Titles and values retain the measured Turret Road weights. A temporary contrasting outline is used only when a moving real liquid surface crosses a label.

Search button: (314,256), 24 × 24, radius 9. Settings: (349,245), 36 × 36, radius 10. Power: (395,256), 24 × 24, radius 9. All use #D9D9D9. The updated sidebar button row is (192,192), 141 × 37: power at x192, gear at x244 and bell at x296, each 37 × 37, radius16. The right-anchored status group is (231,159), 102 × 24; Wi-Fi and Bluetooth are 15 × 15 at y163, and its battery label is Nerd Font Mono 12 Bold, 29 × 16 at (275,163). Rail dividers are x1617 and x1840, y21, 36 high, #3A3A3A.

The latest explicit request for identical Figma proportions supersedes the earlier 10% widening: the staged calendar is again 733 × 310, with the original instrument/grid/action origins. The running previously deployed calendar is not silently resized.

## Desktop 2 / Settings

| Layer | Artboard rectangle | Appearance |
| --- | --- | --- |
| Main frame `36:269` | 524,212 / 1024 × 699 | #2C2C2C, radius10 |
| Right pane `36:270` | 786,212 / 762 × 699 | #252525, radius10 |
| Search `36:280` | 586,241 / 186 × 24.17 | #D9D9D9 at 17%, radius4; 16 × 16 search icon at 593,244 |
| Left profile housing `36:281` | 541,290 / 231 × 82 | #6B6B6B, inside1 #898989, radius10 |
| Left portrait `36:282` | 551,299 / 63.95 × 63.95 | radius21, original image crop |
| Left name `36:284` | 630.52,315.1 / 73.81 × 22.14 | plain JetBrains Mono 16 Bold, white |
| Your PC label | 631.06,341.59 / 122.91 × 12.9 | plain JetBrains Mono 10 Regular, white |
| Navigation housing `36:312` | 541,387 / 231 × 215.2 | #6B6B6B, inside1 #898989, radius10 |
| Navigation rows | x551, y397 + 42n | 35 × 35 icon wells, radius8; labels x591, y402 + 42n, Nerd Font Mono 11 Regular |
| Selection `36:369` | 541,473 / 231 × 43 | #535353, radius0 |
| Nav separators `36:313`, `36:338` | x586, y432 + 42n / 162 × 0 | centered1 #FFFFFF |
| Airplane toggle | 706,525 / 54 × 20 | #555555; 26 × 16 #C2C2C2 thumb at 708,527 |
| Right portrait `36:371` | 1109,265 / 116 × 116 | radius21, original image crop |
| Right name `36:373` | 1125,395 / 96 × 28 | plain JetBrains Mono 20 Bold, white |

Both portraits use the original user-supplied `Image_20260928150902_7_3.jpg` (1199 × 1209), whose filename/dimensions match Figma's fill metadata. `G2Image` preserves aspect crop with continuous corners. The measured five-row navigation viewport stays compact; all fourteen functional categories remain accessible through scrolling/search. General retains the sparse measured composition instead of adding status cards to its empty space. Decorative author credit is omitted under the project's functional-text-only rule. The isolated preview matches the artboard window origin; native floating-window placement is still compositor-controlled and not verified at that origin.

Opening is a downward frame reveal, followed by a newly randomized six-part sequence over 1.5 seconds. Rain moves; storm lightning is an occasional pulse. Sidebar translates left-to-right over 280 ms. Reduced motion removes animated transitions. Workspace changes translate a three-position horizontal wheel. Rail hover text stays disabled; accessible names and keyboard activation remain.

## Honest limits

The date grid `20:14` is a raster image (231 × 173 at 498,73; original 636 × 478). Its internal font properties are not exposed as Figma text layers. The functional grid therefore uses inferred small type, selectable dates and minimal month navigation. Media `32:58` and some supplied content are also raster assets, so exact internal type/geometry cannot be measured from editable layers. The sidebar dot-pattern source, thin external scrollbar at (368,452), native Settings placement, unmeasured pencil control and exact image transforms remain pending. G2 continuous corners are explicitly requested but are not claimed to reproduce every Figma smoothing parameter.

Fourteen Settings pages exist with independent backends. An embedded equalizer, notification history, independent lock, broader legacy migration and direct native input validation remain unfinished. No claim of every Figma detail being identical or of full prompt completion is made.
