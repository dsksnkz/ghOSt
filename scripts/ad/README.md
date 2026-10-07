# ghOSt product film

A 26-second monochrome film, built from actual ghOSt QML components with
demonstration data. No live workspace, volume, hostname or session action is
changed during production. The supplied reference informs camera movement,
folded geometry and orbital lines; its footage and soundtrack are not reused.

## Render

Requires the already available Quickshell, FFmpeg, Python, NumPy and Pillow.
From the repository root:

```sh
python3 scripts/ad/capture.py
python3 scripts/ad/film.py
```

`capture.py` copies the current component tree into an ignored private runtime,
starts its own offscreen Quickshell instance, and exports 2× native frames.
Its volume adapter changes only that copy, never installed rail code.
`advert.qml` exposes explicit sample-state controls. `film.py` projects those
frames onto moving planes, adds original geometry and synthesizes quiet original
mechanical audio. It encodes 1080p/30fps H.264 with AAC sound.

Cached frames live in `.local/ad-production-hq/`. Remove individual cached
sequence files when intentionally regenerating them after a component update;
the capture command preserves existing exports. Output is
`.local/ad-production-hq/ghOSt-advertisement.mp4`.

Run `python3 scripts/ad/check.py` after rendering to verify native frame coverage,
projection geometry, timeline continuity, dimensions, duration and audio. Decode
the completed video with FFmpeg as a separate final check.

## Sequence

| Time | Content |
| --- | --- |
|0–1.8s|Identity and folded planes|
|1.8–4.8s|Native workspace-wheel motion|
|4.8–7s|Rail volume increases and decreases with scroll cues|
|7–12s|Calendar reveal, animated weather, telemetry, CPU/clock and month change|
|12–15s|Grouped sidebar reveal, network, Bluetooth, audio and brightness|
|15–23.4s|General, Battery, Storage and System Info|
|23.4–26s|Layered composition and identity|

The native interfaces are genuine component exports; values are illustrative,
not a recording of current battery/weather/hardware activity. Private chats,
nearby SSIDs, the user's OBS recording and the reference audio are excluded.
