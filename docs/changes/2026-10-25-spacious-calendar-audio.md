# Spacious calendar and media popup — 25 October 2026

User: "the ui seems cramped abit in space. redesign in a more modern ui. also
redesign the audio bar in top bar". Follows the same-day rail/calendar redesign.

## Calendar

- Design plane enlarged from 733 × 310 to 820 × 380, now `Theme.calendarPlaneWidth`
  / `calendarPlaneHeight`; `Theme.calendarWidth` and the window use them. At
  1920 × 1080 the window is about 918 × 425.
- New header: the selected date in 26 px Light (`Today` or the year beneath),
  with Applications/Settings/Power as 36 px tonal tiles on the right. Clicking
  a day updates the header.
- Column dividers removed; columns separated by whitespace under one hairline.
  Sentence-case captions (Weather, System, month).
- Gauges are rounded 4 px fill bars with mono readouts; GPU, Memory, CPU
  (CPU still toggles to clock MHz).
- Forecast: selected day on a tonal rounded row. The wheel now works anywhere
  over the weather column, not only over the list.
- Month grid: 28 px circular day keys; today filled white, a selected day tonal.
- Six-group reveal, weather blur and rain/storm motion unchanged.

## Media popup (`MediaPanel.qml`)

Correction: the user meant the popup opened by clicking the rail's audio
element, not the element itself. The first pass had restyled the compact rail
element; that change was reverted, and `MusicBar.qml` is byte-identical to
`03e6178` again.

- New `MediaPanel.qml` (registered in `qmldir`) replaces the expanded MusicBar
  on the media page. `PanelContent.qml` lets the calendar and media pages draw
  their own header (`ownHeader`); media gets the calendar's frame (`#0b0b0b`,
  `#272727` outline, top highlight). Width stays 392 px; height 262 px.
- Header: "Now playing · <player>" with a 28 px close tile.
- 76 px artwork from MPRIS `trackArtUrl`; without art, seven live Cava bars in
  the tile (flat and faint when idle; Cava runs only while open and playing).
- Title (17 px, up to two lines), artist, album.
- Rounded 4 px seek bar with a knob on hover, click to seek, mono timecodes.
- Transport: −10 / previous / 48 px white play-pause circle / next / +10.
  The old "Stop" button was dropped; pause covers it.
- The expanded mode code in `MusicBar.qml` is no longer used by the popup but
  remains, unchanged, for its existing test.

## Verification

- `verify_input.py` (music test unchanged, as MusicBar is restored),
  `verify_rail_clock.py`, `verify_surface_compile.py`, `verify_calendar.py`
  (ratio updated to 820/380), and 83 Python tests pass.
- `compile-surfaces.qml` now also compiles `MediaPanel.qml` and `PanelContent.qml`.
- Media page opened in the offscreen preview through the real popup path with
  no QML warnings; a sample track was rendered offscreen.
- Deployed in two batches, each with one automatic reload and `Configuration
  Loaded`: calendar (`Theme`, `CalendarPanel`, `CalendarWindow`), then
  `MediaPanel`, `qmldir`, `PanelContent` and the restored `MusicBar`. CS2 was not running.
- Not done: neither popup was opened on the live desktop; artwork loading
  from a real player is untested.

Evidence (local only): `.local/verification/2026-10-25-spacious-calendar-audio/`.
Rollback: copy `.local/backups/2026-10-25-spacious-calendar-audio/live/*` into
`~/.config/quickshell/ghost-bar/`.
