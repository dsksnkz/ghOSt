# Rail music background

Request: "the music visualiser is now 15 bars directly in the background of the
whole music thing"; enlarge only the rail music text and move Cava behind it.

Compact MusicBar now draws fifteen evenly spaced bars across its full 260×32
design area, behind both title and transport keys. The title increases from 9
to 13px JetBrains Mono (11.7px after the existing rail scale); its left inset is
6px because no separate spectrum column remains. Other rail fonts, rail size,
transport actions and expanded media panel typography are unchanged.

AudioSpectrum owns a Cava stdout process with a dedicated config: mono, fifteen
bands, 30fps, default Pulse-compatible output monitor, ASCII range 0–1000. Frames
must contain exactly fifteen valid bounded values. Malformed frames are ignored.
No audio samples or media metadata are stored. The process stops when playback
stops, rail is hidden/fullscreen, or reduced motion is enabled. Fixtures never
start Cava. Missing Cava leaves flat bars; no synthetic spectrum replaces it.
The existing expanded-panel playback indicator remains separate.

Verification: actual isolated Qt suite passes with fifteen background items,
full-width geometry, 13/18px compact/expanded fonts, valid and rejected frame
parsing, silent fixture process and existing media geometry/time formatting.
Production types compile. Installed Cava returned fifteen-value raw frames;
the live ghOSt Cava process was observed during user playback. Hot reload loaded
without new QML errors, compositor errors empty. Four deployed files match
source. Subjective frequency response and physical transport interaction were
not changed or independently retested.

![Actual lower music background crop](../images/2026-10-09-music-background/music-background-native.png)

The actual desktop screenshot publishes only the lower background strip so the
user's media title remains private. Full local captures remain ignored; font
size is checked in Qt. Screenshot is a small native crop, not a demonstration
of all fifteen full heights or a fabricated audio fixture.

Snapshot: `.local/backups/2026-10-09-music-background-CGb9ud/` contains affected
project and original live runtime files. No system audio level, shortcuts,
wallpaper, other shell or user Cava configuration was changed.
