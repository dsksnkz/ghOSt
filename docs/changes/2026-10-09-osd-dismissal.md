# OSD and native outside-click fixes

The user reported that Sidebar still would not close outside, requested publishing
every completed ghOSt change, then reported the old OSD remained visible and
requested removing the little horizontal bar from the new volume indicator.

## Sidebar: actual compositor cause and proof

Sidebar requested `WlrKeyboardFocus.Exclusive`. This laptop's Hyprland 0.56.2
also redirects pointer events to exclusive layer surfaces, including coordinates
outside the card. The full-screen dismissal window therefore never received the
outside press. The earlier isolated Qt handler test could not detect this.
The relevant [installed-revision compositor code](https://github.com/hyprwm/Hyprland/blob/efb50993780079460b0cbed1363e2166a2de1d9f/src/managers/input/InputManager.cpp)
checks `m_exclusiveLSes` before normal layer hit testing.

Sidebar now requests OnDemand focus and joins the existing managed focus group.
Inside controls remain usable, outside presses reach the dismissal route, and
Escape works immediately after opening. No visual geometry or shortcuts changed.
`bar.dismissal` exposes only window geometry and dismissal counters, no private
network/notification content.

`scripts/verify_native_dismissal.py --native` sends real compositor mouse/key
events through the already-running ydotool service to the production ghOSt
instance. An inert top-layer test guard protects applications if a click passes
through. A positive control first proves injection reaches that guard; tests
then assert the card opens, an inside blank-frame click does not close it,
outside input closes it and no press reaches the underlying guard. Left, right
and middle outside clicks, immediate Escape, Calendar and Media outside clicks
all pass. This replaces the earlier unverified physical-pointer claim.

The first manually controlled guard was left visible during diagnosis. It was
removed when the user reported it. The published guard now has a five-second
self-expiry; the test also always stops only its own child and restores the
pointer, including on assertion/IPC failure. Native tests require explicit
`--native`; normal test suites do not display anything.

## OSD

The old `Osd.qml` already had `visible: false` on disk, but the legacy instance's
last recorded configuration reload was October 7: that edit had not reached its
running component. Hiding its source was therefore insufficient. The local
`PopoutManager.qml` no longer instantiates `Osd {}` at all. An explanatory root
comment triggered a verified legacy hot reload on October 9 at 15:09:49 London
time. Its PID 1824 remains unchanged; its unrelated services remain active.
No old OSD window can be created by that manager now.

The ghOSt slider's white 30×7px horizontal cap is replaced by an empty handle
item. The liquid fill itself indicates the level; Qt's track/touch drag behavior
remains. Successive follow-ups tighten horizontal spacing, darken the theme and
then make both the overall panel and the inner bar slimmer. The final card is
44px (originally 76px), the track 16px (originally 22px), with 14px side padding
(originally 27px). Its 44px touch target remains wider than the track.
Card/track/border become darker
`#151515`/`#2c2c2c`/`#393939`; vertical proportions stay unchanged.
A native, read-only display request showed the real volume percentage
with no cap; no volume/brightness setter was used. Only `ghost-osd`, not the old
`osd` namespace, mapped during inspection. Physical touch remains untested.

ghOSt also inhibits Quickshell's generic developer reload panel, which can look
like an unrelated grey popup while building. Runtime errors remain in the log;
notification banners and actionable desktop error messages are not disabled.

## Verification and native captures

- 62 Python tests, actual isolated Qt input checks and production windowless
  surface compilation pass. The six real native input cases above pass.
- Files match the installed ghOSt profile; both shell PIDs are unchanged.
  Hyprland configuration errors are empty. Notifications remain ready in
  observation mode, preserving their existing server. No package installation,
  wallpaper/autostart change, process-wide stop or session/power action occurred.
- [Volume panel without cap](../images/2026-10-09-osd/volume-native.png).
- [Sidebar before the outside press](../images/2026-10-09-osd/sidebar-open-native.png)
  and [after dismissal](../images/2026-10-09-osd/sidebar-closed-native.png). These
  are actual native header crops over the inert diagnostic backdrop, not a
  replacement desktop design. SSIDs, private media titles and application content
  are excluded.
- Default-branch prompt/design hashes match local copies:
  `f1c5f9ed4c10315c5f99f4ee83fcf28e9a8abb8d`,
  `9cc34c7e555a0cbfbff777d194a13ac3b799e6fe`,
  `8b137891791fe96927ad78e64b0aad7bded08bdc`.

## Migration and recovery

ghOSt's full runtime and tests are published; private legacy settings/source are
not copied into this independent rice. The complete local legacy change is:
remove `Osd {}` from the existing manager, then reload that existing configuration.
This is not an automatic installer step on other machines, nor permission to
disable unrelated legacy modules or steal their notification service.

The interrupted Sidebar pass's exact originals are in
`.local/backups/2026-10-08-outside-click-5Kup59/`. Today's OSD, documentation,
installed files and affected legacy root/manager originals are in
`.local/backups/2026-10-09-osd-nVhhIx/`. Restore only the affected paths after
reconciling later edits, then reload their configuration. No broad reset is needed.

Published `aea9b3e`. A fresh committed archive passes all 62 Python tests, Qt
input checks and windowless surface compilation. Remote revision and changed
runtime/native-image blob hashes match; installed runtime files match the source.
The user's standing instruction is to publish every completed, verified ghOSt
change. Private files and unrelated edits remain excluded.
