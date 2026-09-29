# 2026-09-29 / Top bar surface

Four functional changes shipped:

- Replaced the colored identity tile with the ghOSt turret-road G mark and a local Canvas icon pack.
- Moved the rail to a strict black/white palette with quieter spacing and no hover expansion.
- Added a click-merge panel motion and fixed-width audio control so controls remain immediate.
- Added a live radial performance instrument to Calendar. CPU, GPU and processor MHz are swappable; illuminated ticks encode the value without a needle.

Files: config/quickshell/ghost-bar/{Bar.qml,Desk.qml,Icon.qml,Key.qml,Panel.qml,PerformanceGauge.qml,Theme.qml,qmldir}.

Live verification:

- Quickshell instance ghost-bar loaded from /home/matte/.config/quickshell/ghost-bar/shell.qml.
- Serpantinum remained running; no keybind or third-party source was changed.
- qmllint config/quickshell/ghost-bar/*.qml passed.
- Screenshots: assets/top-bar-20260929.png, assets/calendar-performance-20260929.png, assets/audio-panel-20260929.png.
- Wallpaper source inspected at /home/matte/Downloads/9c9ce5153911665.63385705a0c1d.webp; a separate copy is published at site/assets/wallpaper.webp.
- Preview: https://dsksnkz.github.io/ghOSt/ after the Pages workflow completes.

Rollback: restore .local/backups/20260929-topbar-monochrome/installed-before to ~/.config/quickshell/ghost-bar, then restart only the ghOSt shell.
