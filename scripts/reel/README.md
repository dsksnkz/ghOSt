# ghOSt showreel

A 20-second, 1920 × 1080, 60 fps motion-graphics reel cut to the music. Every
interface shown is a real ghOSt component exported offscreen with sample data
(`capture.py` + `reel-capture.qml`); the login screen is the real SDDM theme preview.

```sh
python3 scripts/reel/capture.py   # real component frames -> .local/reel/
python3 scripts/reel/render.py    # -> .local/reel/ghOSt-showreel.mp4
python3 scripts/reel/render.py preview 2.0 4.7 9.6   # single frames for review
```

`GHOST_REEL_SPEED=0.85 python3 scripts/reel/render.py` renders the same reel 15%
slower (`ghOSt-showreel-85.mp4`, 23.5 s): scene time is scaled, the music is
time-stretched with pitch kept and delayed 14 ms to cancel the stretch's transient
shift. Measured: all 27 kicks within one frame (median 1.7 ms).

The soundtrack is `~/Downloads/mixkit-cbpd-400-20s-drop2.mp3` (the 20 s cut with the
beat entering at 0:02). It is not committed.

## Desktop showcase (`showcase.py`)

A 20 s, 3840 × 2160, 60 fps "screen recording" in the r/unixporn style, adapted to
ghOSt from a Catppuccin/Waybar brief: the ghost wallpaper with slight parallax,
the real rail sliding in on the drop, frosted fastfetch (ghost block-art logo,
no brand logos) and monochrome btop tiles, horizontal workspace slides to Neovim
(a real ghOSt source file) and a dark start page, the real launcher typing
"ghost", ghOSt Intro opening as its real floating window while a terminal tiles
in (dwindle), a top-centre toast, the media popup with a spectrum pulsing on the
kicks, a slow push-in with shallow focus, then windows closing back to the rail.
No cursor. Window hairline borders with a slow sheen are cinematic styling; the
user's real Hyprland config has borders off.

```sh
systemd-run --user --wait --collect -p MemoryMax=5G -p MemorySwapMax=0 \
    nice -n 10 python3 scripts/reel/showcase.py
```

Run it in a memory-capped scope. At 4K, live audio muxing made ffmpeg buffer the
slow video for interleaving and memory grew without bound (it OOM-killed the
desktop app once); the script now encodes video alone and adds the music in a
second copy pass, with small caches and a bounded batch pipeline. Measured peak:
2.9 GB.

## Beat map

Measured from the soundtrack, not assumed from a tempo: kick onsets from the low
band and clap onsets from the high band, by energy threshold at 5 ms resolution.
The track is about 144.6 BPM in half-time with syncopated kicks (3+3+3+5+2
sixteenths), so cuts follow the measured `KICKS` and `CLAPS` lists in `render.py`,
not a fixed grid. Bars are 1.6588 s from the drop at 1.96 s.

Each hit maps to the nearest frame (half-frame tolerance). Verified on the final
encode: all 38 kicks and claps produce a visible change on their nearest frame,
median 0 ms and worst 8.3 ms from the audio onset.

## Style rules (from review)

- Text is plain: pure white (black on light fields), drawn on a final clean layer
  after grain and colour, never scaled, split or flashed.
- No per-beat camera punches or colour splits. Beats land as clean events:
  cuts, cursor clicks, page changes, callouts landing, elements arriving.
- Features are demonstrated, not described: a cursor scrolls the workspace wheel,
  clicks the clock (calendar opens), scrolls the forecast, opens media from the
  rail and drags seek, opens the sidebar from the menu and drags volume, and
  clicks through Settings.

Sync check (block-based, so local events count): 36/38 hits detected on the
20 s cut, median 2.5 ms; the other two (callout landing at 5.275 s, password and
callout at 16.475 s) were confirmed on the frames by eye.

## Detail layers

Every scene sits on a dimmed, drifting composite of the real desktop (wallpaper
plus rail, and the panels where relevant). Feature callouts point at measured
positions inside the captures (`RAIL_POINTS`, `CAL_POINTS`, `MEDIA_POINTS`,
`SIDE_POINTS`, `SDDM_POINTS`) and draw in on the hits; magnifier lenses show the
workspace wheel, clock and status area; gauge values count up; a frame-time trace
shows the measured 5.1 ms frame interval; the open-source section scrolls the
project's real commit subjects. A HUD frame carries the section, timecode, bar
count and progress.

## Sequence

| Time | Bar | Content |
| --- | --- | --- |
| 0-1.96 | intro | "every rice looks the same.", ghost x-ray outline scan, build |
| 1.96 | drop | ghOSt slam, invert, blue clap: "a desktop shell for Hyprland" |
| 3.62 | 2-3 | Desktop plate tilts into an exploded x-ray layer stack; scan band reveals real pixels; layer labels on kicks; "every layer, designed." |
| 6.94 | 4 | Rail framings cut on hits, workspace wheel, x-ray echo: "detailed down to the pixel." |
| 8.60 | 5 | Calendar subframe reveal, red x-ray sweep: "useful at a glance." |
| 10.26 | 6 | Media popup drops in, sidebar reveals: "built for every day." |
| 11.92 | 7 | Settings pages cut per hit, outgoing page as x-ray: "14 pages of settings." |
| 13.58 | 8 | Onion-skinned entrance motion: "motion that feels right." |
| 15.24 | 9 | SDDM login, password filling on hits, x-ray sweep: "from login to lock screen." |
| 16.90 | 10 | "created by / me. / and you. / open source." on colour blocks |
| 18.56 | 11 | Ghost mark, ghOSt, repository URL on the last clap, fade with the music |

Palette: off-black and off-white, with electric blue, signal red and acid lime on
claps. Claims are factual: Settings has 14 pages; the 200 Hz line comes from the
measured frame pacing on the author's 200 Hz display.
