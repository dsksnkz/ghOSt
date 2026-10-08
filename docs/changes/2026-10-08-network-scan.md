# Sidebar and Settings Wi-Fi discovery

The scanner was enabled only when the old `network` popup changed state.
Sidebar and Settings Wireless Network lists never requested discovery themselves,
so they could retain previously discovered networks.

`NetworkScanPolicy.js` expresses one condition: an available, enabled Wi-Fi
device scans while the network popup, enabled Sidebar network widget, or actual
visible Settings Wireless Network page is open. `Desk.qml` binds that condition
to the device; `SettingsWindow.qml` reports its actual content page. Closing a
browser releases ghOSt's demand, unless another network browser remains visible.
The conditional Qt binding also follows device removal/replacement.

The installed [Quickshell Wi-Fi API](https://github.com/quickshell-mirror/quickshell/blob/master/src/network/wifi.hpp)
uses `scannerEnabled` for discovery. This does not call connection, disconnection
or radio-toggle actions. [Qt Binding](https://doc.qt.io/qt-6/qml-qtqml-binding.html)
provides the conditional target binding and default restoration. Other clients
may still scan independently; no CPU, battery or FPS improvement is quantified.

## Verification

- `node tests/test_network_scan.cjs`: all 128 visibility, device, radio and widget
  combinations pass, including scanner release.
- `python3 scripts/verify_network_scan.py`: 12 actual windowless Qt transitions
  pass, including page changes, missing/replaced devices and binding restoration.
  The test imports no Networking service and cannot change the system radio.
- 61 Python tests pass, including installer/distribution checks. Existing wheel,
  launcher, continuous-corner and cached-wave JS checks pass.
- Actual native diagnostics: closed = scanner off; Sidebar = on; closed = off;
  Settings Wireless Network = on; General = off; old network popup = on;
  Calendar = off. Native header inspected and captured without network names:
  [Wireless Network control](../images/2026-10-08-network-scan/settings-wireless-header.png).
  This verifies scan demand, not newly introduced physical access points or a
  connection attempt. No private network list is published.
- All four runtime files match the installed ghOSt files. Hot reload loaded the
  configuration but retained old IPC metadata, so only named instance
  `jlf27h1kmt` was restarted. New instance `lnr4q5kkmt`, PID 222465, loads cleanly.
  Legacy PID 1824 remains unchanged; notifications remain in observation mode.
- Ethernet and Wi-Fi connections remain connected. No credentials or profiles
  changed. Rail reservation remains 50px; compositor errors are empty. Binding
  SHA-256 remains
  `3933ec4838952df5fb833b523d64ef9eeb56ee823c043d695d9447e6930fbc05`.
  All inspected surfaces returned to their initial closed state.

No UI size, font, radius, spacing, animation, shortcut, wallpaper, autostart or
website layout changed. No editable Figma tab was available; the supplied design
composition was read and retained. No new parity claim is made. Current remote
and local prompt/design Git blobs match:

- `prompts.md`: `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`
- supplied design image: `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`
- `mainDesigns/1`: `8b137891791fe96927ad78e64b0aad7bded08bdc`

The broader Figma/reference, embedded equalizer, independent lock and migration
backlog remains pending.

Published source release `7bee15a` to GitHub `main`. A fresh archive passes all
61 Python tests, 128 policy cases, 12 windowless Qt transitions and the existing
JS regressions. Remote Git blob hashes match the new policy and privacy-safe
native screenshot. Live ghOSt remains loaded with all inspected surfaces closed.

## Recovery

Snapshot `.local/backups/2026-10-08-network-scan-hSroSO/` preserves the exact
affected project and live files before edits. Restore the three originals from
its `live/` folder into the existing ghOSt profile, then restart only that named
ghOSt instance. The new policy file can remain unused after restoration. No
other rice or system service needs changing.
