# Left rail dividers

Removed only the two separator surfaces at design x96.5 and x272.5 between
menu, workspaces and music. Component positions, music typography/background,
outer rail outline and right-side dividers are preserved.

Production surfaces compile and `git diff --check` passes. Live hot reload
reports Configuration Loaded; the deployed Rail.qml matches source.

![Native rail without left separators](../images/2026-10-09-left-dividers/left-rail-native.png)

Actual desktop crop includes both removed separator positions and excludes
private media titles. Recovery snapshot:
`.local/backups/2026-10-09-left-dividers-BqWMZi/`.
