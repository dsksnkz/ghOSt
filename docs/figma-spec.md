# Figma measurements / 2026-10-03

Source: the signed-in [user design](https://www.figma.com/design/AaDuLbS8jYez060Nm7bOnw/hyprland-rice-design--Copy-). Measurements were read from the visible Design properties, including nested layers and gradient stops. Coordinates below use the 1920 × 1080 artboard, not the browser's zoomed screenshot. No design content was intentionally changed.

## Coordinate system

`scale = outputLogicalWidth / 1920`. Coordinate, spacing, font size and radius all use that same scale. The current 1920-pixel monitor has 2304 logical pixels; its 1.2 UI scale is canceled by the compositor's 0.833333 output scale. No monitor setting was changed.

| Surface | Artboard rectangle | Fill | Radius / stroke |
| --- | --- | --- | --- |
| Rail `1:4` | 19,16 / 1882 × 46 | #2B2B2B | 7 / outside 1 #4D4D4D |
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

Turret Road Regular/Medium/Bold are bundled under their existing OFL license. The installed Nerd Font Mono supplies the JetBrains Mono base glyphs, including Light; this is not a claim that an additional plain JetBrains Mono family was installed.

## Calendar and controls

GPU/RAM squares are 87 × 87, 45° rotation, radius 15, #313131; their rotated bounding boxes are 123 × 123. Background origins within the frame are GPU (235,27), RAM (375.01,27), CPU (305,97.01). Titles and values retain the measured Turret Road weights. A temporary contrasting outline is used only when a moving real liquid surface crosses a label.

Search button: (314,256), 24 × 24, radius 9. Settings: (349,245), 36 × 36, radius 10. Power: (395,256), 24 × 24, radius 9. All use #D9D9D9. The sidebar's sun-shaped Settings button is (223,192), 37 × 37, radius 16; the bell is (296,192), 37 × 37. The calendar Settings symbol is a solid gear, not a sun.

Opening is a downward frame reveal, followed by a newly randomized six-part sequence over 1.5 seconds. Rain moves; storm lightning is an occasional pulse. Sidebar translates left-to-right over 280 ms. Reduced motion removes animated transitions. Workspace changes translate a three-position horizontal wheel. Rail hover text stays disabled; accessible names and keyboard activation remain.

## Honest limits

The date grid `20:14` is a raster image (231 × 173 at 498,73). Its internal font properties are not exposed as Figma text layers. The functional grid therefore uses inferred small type, selectable dates and minimal month navigation. Media `32:58` and several supplied glyphs are also raster assets, so their exact underlying font/vector geometry cannot be measured from editable layers. Gradient endpoints were not exported; their colors/stops are measured but direction is approximated vertically. The thin external sidebar scrollbar remains pending.

Current live notifications have no independent available daemon: the UI reports this rather than claiming an empty inbox. Direct Bluetooth pairing, new-network authentication, complete notification history, the full Settings application and the independent lock are not completed here. No claim of every Figma detail being identical or of full prompt completion is made.
