# 2026-09-29 / Telemetry and preview correction

Status: staged and published for review. The active rice was not changed.

## Changes

- Real CPU utilization from /proc/stat deltas; average processor MHz from /proc/cpuinfo; GPU utilization from NVIDIA or a supported DRM counter. GPU is queried only while selected. Unknown values are never represented as zero.
- A 60-tick radial instrument, animated fill, larger Qt-rendered numerals and explicit unavailable states. Processor scale reads the hardware maximum.
- Actual Turret Road G bundled with its OFL; fixed network icon/label overlap, black/white icon variants, keyboard button focus, neutral grayscale material and quieter texture.
- Panel scale originates at the clicked control. Rail and PanelContent are reusable production components rendered by the isolated preview harness.
- Default install now stages only; --activate is an explicit integration action.
- Pages now switches between six clean surface renders. It uses a separate copy of the inspected laptop wallpaper and self-hosted fonts.

## Checks

Six telemetry tests passed: guest accounting, CPU delta math, reset counters, frequency averaging, missing GPU, timeout/zero GPU. The actual QML renderer reported CPU 3.3%, GPU 16%, and processor 1003 MHz with a 4600 MHz scale at separate sample times. Values fluctuate; screenshots capture later frames.

The metrics child process exits when the calendar is unloaded. Offscreen startup has only the expected missing-Hyprland/window-mask platform warnings; no Canvas font warnings or QML exceptions. Native Serpantinum and ghost-bar process IDs survived. Live keybind JSON was byte-identical.

Installer staging was exercised at .local/verification/install-fixture. Browser preview controls were checked; the 390px viewport had no horizontal overflow. No native focus, network reassociation, audio change, lock, logout or power action was exercised.

## Screenshots

These are actual QML component renders in isolation, not screenshots of the user's applications.

- [Rail](../../site/assets/top-bar.png)
- [CPU](../../site/assets/calendar-performance.png)
- [GPU](../../site/assets/calendar-gpu.png)
- [Processor clock](../../site/assets/calendar-clock.png)
- [Audio](../../site/assets/audio-panel.png)
- [White and black icons](../../site/assets/icons.png)
- [Website](../../assets/site-20260929.png)
- [Mobile website](../../assets/site-mobile-20260929.png)

[Live preview](https://dsksnkz.github.io/ghOSt/). Image values are snapshots; the website does not control or remotely monitor the laptop.

## Recovery and correction

Pre-change files are retained privately at .local/backups/20260929-1218. No live rollback is needed because this revision was not activated.

The earlier change record incorrectly claimed a real three-metric monitor; that revision used load average and constant zeros. Its fullscreen chat captures have been replaced in the current tree and Pages assets, but remain in earlier Git commits. Purging published history is a separate operation.
