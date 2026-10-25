# Rail and calendar redesign — 25 October 2026

User: "remake the calendar bar / the top tray using your own design. dont overload
the features, keep it minimalist, but zero AI ui slop. add style". Clarified scope:
both the top rail and the calendar popup; deploy when tested.

## Direction

Monochrome instrument panel: near-black housing (`#0b0b0b`), `#272727` outline,
a 6% white hairline inside the top edge, JetBrains Mono for every numeral and
small letter-spaced captions for section labels. No glow, gradient, colour or
new features. Hover still changes colour, never scale.

## Rail (`Rail.qml`)

- Same height, reservation, positions, layout editor and element IDs.
- Day scale on the lower edge: 25 hour ticks, quarter-day marks and one white
  notch at the current time of day (from `Desk.now`; no timer added).
- Clock in JetBrains Mono 24 px with four viewfinder corners. The centre still
  contains only the clock text.
- Separators shortened to 14 px hairlines. Battery reading in mono.
- Removed the radial glow behind the power icon.

## Calendar (`CalendarPanel.qml`, `CalendarWindow.qml`)

- Same 733 × 310 plane, window geometry, six-group randomized 1.5 s reveal,
  forecast selection/wheel, weather blur and rain/storm motion.
- Three columns divided by hairlines: WEATHER, SYSTEM, month.
- Weather: animated glyph, mono temperature with °C, condition, five-row forecast
  with a white marker on the selected day.
- System: the three liquid diamonds are replaced by segmented 40-tick gauges
  (major tick every 10%) with mono readouts. CPU still toggles to clock MHz.
  No shader or per-frame animation: level changes ease over 320 ms. This also
  removes the calendar's continuous liquid rendering cost. `LiquidMeter.qml`
  is kept but no longer used by the calendar.
- Applications/Settings/Power as three equal outlined keys.
- Month grid in mono; today inverted, a different selected day outlined,
  weekends muted, other months faint.

## Verification

- `verify_rail_clock.py`, `verify_rail_layout.py`, `verify_surface_compile.py`,
  `test_rail_layout.cjs`, 83 Python tests and the site test pass.
- `verify_calendar.py` passes against an offscreen fixture preview with no QML
  warnings in its log.
- Deployed `Rail.qml`, `CalendarPanel.qml`, `CalendarWindow.qml`. CS2 was not running.
  One automatic reload, `Configuration Loaded`. A live rail capture showed the new
  housing, clock corners and the time notch at the correct position.
- Not done: the calendar popup was not opened on the live desktop, so its native
  look is checked only in the offscreen fixture render.

Evidence (local only): `.local/verification/2026-10-25-rail-calendar-redesign/`.
Rollback: copy files from `.local/backups/2026-10-25-rail-calendar-redesign/live/`
into `~/.config/quickshell/ghost-bar/` (one automatic reload).
