# Calendar weather loading

Repeated calendar openings now reuse a private recent Open-Meteo observation
instead of waiting for another HTTPS request every time. The 15-minute limit
matches the existing calendar refresh interval. Location changes, local midnight
in the forecast's timezone, clock rollback, expired/corrupt data and unknown
timezones require a fresh request. Expired readings are never presented as current
when that request fails. The headline and Today still share the same observation.

`weather.py` adds focused read/write cache helpers. Atomic 0600 writes keep
coordinates private and prevent partial reads. Cache-write failure leaves a valid
network result usable. The cache is local under `$XDG_CACHE_HOME/ghost/weather.json`
and is not included in GitHub. Simultaneous cold readers can still each request
the provider; this is not a global request scheduler.

## Verification

- 61 Python tests pass, including 10 new cache regressions for expiry, location,
  midnight, rollback, failure, privacy and current/Today agreement.
- Existing wheel, corner, wave geometry and 15 launcher assertions pass.
- Native helper installed byte-identically into the existing ghOSt profile.
  Reopening the calendar reused the same cache timestamp; the actual calendar
  showed matching current/Today readings. [Native output](../images/2026-10-07-weather-cache/calendar-native.png).
- One local cold call and two warm calls took 120.818ms, 0.203ms, 0.057ms in-process.
  Two separate installed CLI runs took 194.764ms and 47.353ms, including Python
  startup. These are indicative request-path samples, not whole-desktop/FPS,
  CPU/power or long-duration benchmark claims.
- Named ghOSt PID113527 and legacy PID1824 preserved; no restart required.
  Existing rail 50px reservation, clean native logs and empty compositor errors
  checked. Live bindings SHA-256 unchanged:
  `3933ec4838952df5fb833b523d64ef9eeb56ee823c043d695d9447e6930fbc05`.

No UI geometry, font, corner, hover or animation changed. No editable Figma tab
was open in the available browser; the supplied mainDesigns composition was read
and retained. Remote/local prompt/design blobs still match:
`f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`,
`9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`, and
`8b137891791fe96927ad78e64b0aad7bded08bdc`.
Broader Figma parity, embedded EQ, independent lock and migration remain pending.
No website preview or private desktop/history capture was rebuilt/published.

## Recovery

Snapshot: `.local/backups/2026-10-07-weather-cache-CSyhfN/` preserves the exact
source, tests, documentation and installed weather helper before editing.
Restore `live-weather.py` over the named ghOSt helper to roll back. The new cache
can remain unused; no original config/location file was changed or removed.

Source, tests and the privacy-safe native screenshot are included in this
verified release; publication is checked separately after committing.
