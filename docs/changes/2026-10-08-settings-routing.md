# Settings page requests

Reproduced before editing: `bar.settings general`, followed by
`bar.settings storage` while the window remained visible, left the actual page
on General. `SettingsWindow.qml` selected a requested page only when visibility
changed. A later request to an already-open window was ignored.

`Desk.openSettings()` now emits a navigation request every time, rather than
relying on a changed page string. The focused nonvisual `SettingsNavigation.qml`
component handles this request and window activation. It chooses the latest
requested page and gives its content keyboard focus. Repeated requests work even
after the user has browsed elsewhere locally. Closing before the deferred callback
prevents navigation/focus work on a hidden window.

One shared [Qt.callLater callback](https://doc.qt.io/qt-6/qml-qtqml-qt.html#callLater-method)
coalesces requests within the same event-loop turn, avoiding redundant page
animation/layout resets. No timer, backend action, new shortcut or IPC method is
introduced. Actual-page scanner and refresh bindings retain their existing logic.

## Verification

- `python3 scripts/verify_settings_navigation.py`: 10 actual production-router
  Qt transitions pass, including closed/open states, repeated unchanged requests,
  local browsing followed by a repeated request, burst coalescing and closing
  before the callback. The root has no window or system-service imports and uses
  inert controller/content objects. No visual preview or system action runs.
- All 61 Python tests and existing network policy, workspace wheel, launcher,
  continuous-corner and cached-wave JS checks pass.
- `python3 scripts/verify_settings_polling.py` still passes all page intervals,
  immediate refresh, real five-second timer, hidden release and fixture guard.
- Native integration: all 14 pages routed while the same Settings window stayed
  open, followed by repeated General requests and Storage. Every actual page,
  5s/60s refresh interval and Wi-Fi discovery demand matched expectations. This
  verifies native IPC navigation, not physical mouse navigation or compositor
  activation/focus behavior.
- Four runtime files match the installed ghOSt files. Hot reload succeeded;
  ghOSt PID 222465 and legacy PID 1824 are unchanged. Settings remains 1024×699
  at (448,216). No new warning appears after this reload. Older logs contain
  monitor-removal/optional-bool and departed MPRIS-service warnings; those are
  separate pending checks, not claimed repaired here.
- Rail reservation remains 50px and compositor errors are empty. Ethernet and
  Wi-Fi remain connected; notifications remain in observation mode. Live binding
  SHA-256 remains
  `3933ec4838952df5fb833b523d64ef9eeb56ee823c043d695d9447e6930fbc05`.
  Panel state returned to closed; audio/workspaces were not changed by tests.

No dimensions, font, corners, layout, wallpaper, autostart or system preferences
changed. No editable Figma tab was available; the supplied design was read, not
redesigned. Remote/local prompt and design blobs match:
`f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`,
`9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`, and
`8b137891791fe96927ad78e64b0aad7bded08bdc`.
The [earlier native Storage capture](../images/2026-10-08-settings-polling/storage-native.png)
is only a reference for the unchanged visual material, not fresh evidence for
this routing pass.

## Capture checkpoint resolved by the direct interaction pass

The final native capture encountered a foreground game instead of Settings. That
frame is retained privately at `.local/verification/settings-routing-interrupted-capture.png`
and must not be published. Further native UI inspection stopped to avoid disturbing
gameplay. The already-tested change remains live, but fresh screenshot evidence,
committed-archive verification and publication are pending. Resume when gameplay
is not foreground; do not close, alter or refocus the game for verification.
That checkpoint is now resolved: a privacy-safe actual native
[Settings navigation crop](../images/2026-10-08-interactions/settings-navigation-native.png)
was inspected during the later authorized interaction pass. The routing change
is included in that release. The full design/backend backlog remains unfinished.

## Recovery

Snapshot `.local/backups/2026-10-08-settings-routing-e1UOEO/` holds the exact affected
source, documentation and three live originals. Restore its `live/` Desk.qml,
SettingsWindow.qml and qmldir into the existing ghOSt profile to roll back. The new
router file can remain unused. No unrelated service or rice needs changing.
