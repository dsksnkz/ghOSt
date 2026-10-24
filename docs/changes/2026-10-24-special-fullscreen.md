# Hide the rail over fullscreen special workspaces

The reported case was reproduced from the running compositor: a fullscreen
browser on the visible special workspace had fullscreen and fullscreenClient2;
the monitor's normal active workspace was nonfullscreen. `Bar.qml`'s shared state
looked only at `monitor.activeWorkspace.hasFullscreen`, missing that visible app.

`FullscreenState.qml` now resolves `monitor.lastIpcObject.specialWorkspace.id`
against Quickshell's typed workspace model. It hides for fullscreen in either
visible normal/special workspace, not fullscreen windows on hidden special
workspaces or other monitors. An absent monitor still leaves controls usable.
`EdgeHandle.qml` reuses this state so its volume targets do not intercept that
fullscreen app's edges. `shell.qml` debounces special/fullscreen events20ms before
refreshing the existing IPC models; no polling, process spawning or app queries.

## Verification

Real Qt input tests cover regular fullscreen entry/exit, special entry/exit,
hidden specials, switching to an unrelated special ID, null monitors and
restoration. Production compile and regression suite pass. Deployed only these
three runtime modules and reloaded named ghOSt. On the existing untouched native
fullscreen special, read-only diagnostics report railVisible:false and Hyprland
layers contain neither `ghost-bar` nor either `ghost-volume-edge-*` target.
No actual fullscreen toggle, workspace switch or app restart was needed for this
native check; restoration is fixture-tested rather than a claimed native test.
Multiple physical outputs were not available for native verification.

Safe actual fullscreen top-edge crop (the current app displays black):

![Fullscreen top edge without the rail](../images/2026-10-24-special-fullscreen/fullscreen-top.png)

Snapshot: `.local/backups/2026-10-24-special-fullscreen/{project,live}/`.
Restore the affected modules together if required; no geometry, keybinding,
exclusive-zone reservation, app setting, package, service or unrelated file was
changed. Existing unrelated untracked work remains untouched. Remote prompt and
mainDesigns hashes still match local copies from the inspected reference pass.
